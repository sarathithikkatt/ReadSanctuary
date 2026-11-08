package com.shelfcraft.shelfcraft

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import java.io.File

class ShelfCraftWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.shelf_widget_layout)

            // Setup launch intent to open app on widget tap
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.shelf_widget_root, pendingIntent)

            // Retrieve rendered shelf image path
            val imagePath = widgetData.getString("flutter.shelf_widget_image", null)
            val shelfTitle = widgetData.getString("flutter.shelf_widget_title", "ShelfCraft")

            var hasValidImage = false
            if (!imagePath.isNullOrEmpty()) {
                val file = File(imagePath)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.shelf_widget_image, bitmap)
                        views.setViewVisibility(R.id.shelf_widget_image, View.VISIBLE)
                        views.setViewVisibility(R.id.shelf_widget_fallback, View.GONE)
                        hasValidImage = true
                    }
                }
            }

            if (!hasValidImage) {
                views.setViewVisibility(R.id.shelf_widget_image, View.GONE)
                views.setViewVisibility(R.id.shelf_widget_fallback, View.VISIBLE)
            }

            views.setTextViewText(R.id.shelf_widget_title, shelfTitle)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
