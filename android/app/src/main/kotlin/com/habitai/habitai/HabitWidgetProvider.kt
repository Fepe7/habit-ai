package com.habitai.habitai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Widget de pantalla de inicio: anillo de progreso + check-in rápido.
// Lee el payload JSON que publica HomeWidgetService (Flutter) y delega los
// taps de check en el callback Dart de fondo (sin abrir la app).
class HabitWidgetProvider : HomeWidgetProvider() {

    companion object {
        private val ROW_IDS = intArrayOf(
            R.id.widget_row1, R.id.widget_row2, R.id.widget_row3, R.id.widget_row4,
        )
        private val TITLE_IDS = intArrayOf(
            R.id.widget_title1, R.id.widget_title2, R.id.widget_title3, R.id.widget_title4,
        )
        private val CHECK_IDS = intArrayOf(
            R.id.widget_check1, R.id.widget_check2, R.id.widget_check3, R.id.widget_check4,
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = try {
            JSONObject(widgetData.getString("widget_payload", null) ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val payloadDate = payload.optString("date", "")
        val stale = payloadDate.isNotEmpty() && payloadDate != today

        // datos de otro día: pedir al callback Dart que recalcule en fondo.
        // Solo cuando está obsoleto — evita un bucle update→sync→update.
        if (stale) {
            try {
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("habitai://sync"),
                ).send()
            } catch (_: Exception) {
            }
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            val completed = if (stale) 0 else payload.optInt("completed", 0)
            val total = if (stale) 0 else payload.optInt("total", 0)
            val percent = if (total > 0) completed * 100 / total else 0

            views.setProgressBar(R.id.widget_ring, 100, percent, false)
            views.setTextViewText(R.id.widget_count, "$completed/$total")
            views.setTextViewText(
                R.id.widget_percent,
                "$percent% " + context.getString(R.string.widget_today),
            )

            val habits = if (stale) null else payload.optJSONArray("habits")
            val shown = minOf(habits?.length() ?: 0, ROW_IDS.size)

            for (i in ROW_IDS.indices) {
                if (i < shown) {
                    val habit = habits!!.getJSONObject(i)
                    val done = habit.optBoolean("done", false)
                    views.setViewVisibility(ROW_IDS[i], View.VISIBLE)
                    views.setTextViewText(TITLE_IDS[i], habit.optString("title"))
                    views.setTextViewText(CHECK_IDS[i], if (done) "✓" else "")
                    views.setInt(
                        CHECK_IDS[i], "setBackgroundResource",
                        if (done) R.drawable.widget_check_on else R.drawable.widget_check_off,
                    )
                    if (!done) {
                        // check-in en fondo, sin abrir la app
                        views.setOnClickPendingIntent(
                            CHECK_IDS[i],
                            HomeWidgetBackgroundIntent.getBroadcast(
                                context,
                                Uri.parse("habitai://checkin?habitId=" + habit.optString("id")),
                            ),
                        )
                    } else {
                        views.setOnClickPendingIntent(CHECK_IDS[i], launchIntent(context))
                    }
                } else {
                    views.setViewVisibility(ROW_IDS[i], View.GONE)
                }
            }

            // pie: aviso de datos viejos, estado vacío o "+N más…"
            val remaining = total - shown
            when {
                stale -> {
                    views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_footer, context.getString(R.string.widget_stale),
                    )
                }
                total == 0 -> {
                    views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_footer, context.getString(R.string.widget_empty),
                    )
                }
                remaining > 0 -> {
                    views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_footer,
                        context.getString(R.string.widget_more, remaining),
                    )
                }
                else -> views.setViewVisibility(R.id.widget_footer, View.GONE)
            }

            // tocar el resto del widget abre la app
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun launchIntent(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
}
