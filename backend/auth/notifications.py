"""
SpecialCoffee AI — Dispatcher de notificaciones push via OneSignal.

Corre como tarea asyncio en background desde el lifespan de FastAPI.
Loop: cada 60 segundos consulta alert_events donde notification_sent = FALSE
y los despacha a OneSignal. Nunca rompe el loop — los errores se logean y
la ejecución continúa.
"""

import asyncio
import logging
import os
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

ONESIGNAL_APP_ID      = os.getenv("ONESIGNAL_APP_ID")
ONESIGNAL_API_KEY     = os.getenv("ONESIGNAL_REST_API_KEY")
ONESIGNAL_NOTIFY_URL  = "https://onesignal.com/api/v1/notifications"
DISPATCH_INTERVAL_S   = 60
BATCH_SIZE            = 50

# ── Mapeo alert_type → (título, canal Android) ───────────────────────────────

_ALERT_META: dict[str, tuple[str, str]] = {
    "PH_CRITICAL_LOW":        ("⚠️ pH crítico",        "fermentation_alerts"),
    "PH_CRITICAL_HIGH":       ("⚠️ pH crítico",        "fermentation_alerts"),
    "TEMP_CRITICAL_HIGH":     ("🌡️ Temperatura alta",  "fermentation_alerts"),
    "HUMIDITY_CRITICAL_HIGH": ("💧 Humedad alta",       "drying_reminders"),
}

_ALERT_MSG: dict[str, str] = {
    "PH_CRITICAL_LOW":        "Lote {lot_id}: pH {value} — demasiado ácido. Revisa la fermentación ahora.",
    "PH_CRITICAL_HIGH":       "Lote {lot_id}: pH {value} — demasiado alcalino. Revisa la fermentación ahora.",
    "TEMP_CRITICAL_HIGH":     "Lote {lot_id}: {value}°C — riesgo de sobre-fermentación.",
    "HUMIDITY_CRITICAL_HIGH": "Lote {lot_id}: {value}% de humedad — riesgo en el secado.",
}


def _format_value(v: Optional[float]) -> str:
    if v is None:
        return "—"
    return f"{v:.1f}" if v != int(v) else str(int(v))


def _build_message(alert_type: str, lot_id: str, trigger_value: Optional[float]) -> str:
    template = _ALERT_MSG.get(alert_type, "Alerta en el lote {lot_id}.")
    return template.format(lot_id=lot_id[-8:], value=_format_value(trigger_value))


async def _send_push(
    client: httpx.AsyncClient,
    player_id: str,
    alert_type: str,
    lot_id: str,
    trigger_value: Optional[float],
) -> bool:
    """Retorna True si OneSignal acepta el envío (200/201), False en cualquier error."""
    title, channel = _ALERT_META.get(alert_type, ("☕ SpecialCoffee", "fermentation_alerts"))
    message = _build_message(alert_type, lot_id, trigger_value)

    payload = {
        "app_id":             ONESIGNAL_APP_ID,
        "include_player_ids": [player_id],
        "headings":           {"es": title},
        "contents":           {"es": message},
        "data":               {"lot_id": lot_id, "alert_type": alert_type},
        "android_channel_id": channel,
    }

    try:
        resp = await client.post(
            ONESIGNAL_NOTIFY_URL,
            json=payload,
            headers={
                "Authorization": f"Basic {ONESIGNAL_API_KEY}",
                "Content-Type":  "application/json",
            },
            timeout=10.0,
        )
        if resp.status_code in (200, 201):
            return True
        logger.warning("[OneSignal] status %s para alerta %s: %s", resp.status_code, alert_type, resp.text[:200])
        return False
    except Exception as exc:
        logger.error("[OneSignal] error enviando %s: %s", alert_type, exc)
        return False


async def dispatch_pending_alerts(pool) -> None:
    """
    Consulta alert_events WHERE notification_sent = FALSE, intenta enviar
    cada uno vía OneSignal y marca notification_sent = TRUE si el envío
    es exitoso. Silencioso ante errores individuales — siempre continúa.
    """
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT ae.id, ae.user_id, ae.lot_id, ae.alert_type,
                   ae.trigger_value, u.onesignal_player_id
            FROM   alert_events ae
            JOIN   users u ON u.id = ae.user_id
            WHERE  ae.notification_sent = FALSE
            ORDER  BY ae.generated_at
            LIMIT  $1
            """,
            BATCH_SIZE,
        )

    if not rows:
        return

    async with httpx.AsyncClient() as client:
        for row in rows:
            alert_id   = row["id"]
            player_id  = row["onesignal_player_id"]
            lot_id     = row["lot_id"] or "desconocido"
            alert_type = row["alert_type"]
            trig_val   = row["trigger_value"]

            # Usuario sin dispositivo registrado → marcar como enviado y continuar
            if not player_id:
                await _mark_sent(pool, alert_id)
                continue

            sent = await _send_push(client, player_id, alert_type, lot_id, trig_val)
            if sent:
                await _mark_sent(pool, alert_id)
            # Si falla: no marcamos, se reintentará en el próximo ciclo


async def _mark_sent(pool, alert_id: str) -> None:
    try:
        async with pool.acquire() as conn:
            await conn.execute(
                "UPDATE alert_events SET notification_sent = TRUE, notification_sent_at = NOW() WHERE id = $1",
                alert_id,
            )
    except Exception as exc:
        logger.error("[Dispatcher] error marcando alerta %s como enviada: %s", alert_id, exc)


async def notification_loop(pool) -> None:
    """
    Loop de despacho. Corre indefinidamente en background.
    Atrapa todas las excepciones para nunca romper el task de asyncio.
    """
    logger.info("[Dispatcher] Notification dispatcher started (intervalo: %ds)", DISPATCH_INTERVAL_S)
    while True:
        try:
            await dispatch_pending_alerts(pool)
        except Exception as exc:
            logger.error("[Dispatcher] error inesperado en dispatch_pending_alerts: %s", exc)
        await asyncio.sleep(DISPATCH_INTERVAL_S)
