package com.example.ocr_app

import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import org.opencv.imgcodecs.Imgcodecs
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ocr_image_processor"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Asegúrate de inicializar OpenCV correctamente
        System.loadLibrary("opencv_java4")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "deskewImage") {
                val path = call.argument<String>("path")
                if (path != null) {
                    val correctedPath = correctSkew(path)
                    if (correctedPath != null) {
                        result.success(correctedPath)
                    } else {
                        result.error("DESKEW_FAILED", "No se pudo deskew", null)
                    }
                } else {
                    result.error("INVALID_PATH", "Ruta no proporcionada", null)
                }
            }
        }
    }

    private fun correctSkew(imagePath: String): String? {
        val src = Imgcodecs.imread(imagePath, Imgcodecs.IMREAD_GRAYSCALE)
        if (src.empty()) return null

        val edges = Mat()
        Imgproc.Canny(src, edges, 50.0, 200.0)

        val lines = Mat()
        Imgproc.HoughLines(edges, lines, 1.0, Math.PI / 180, 150)

        var angle = 0.0
        val angles = mutableListOf<Double>()

        for (i in 0 until lines.rows()) {
            val rhoTheta = lines[i, 0]
            val theta = rhoTheta[1]
            val degrees = Math.toDegrees(theta) - 90
            angles.add(degrees)
        }

        if (angles.isNotEmpty()) {
            angle = angles.average()
        }

        if (Math.abs(angle) > 15.0) {
            // Ángulo demasiado grande, no rotar
            return imagePath
        }

        val srcColor = Imgcodecs.imread(imagePath)
        val rotated = Mat()
        val center = Point(srcColor.width() / 2.0, srcColor.height() / 2.0)
        val rotMatrix = Imgproc.getRotationMatrix2D(center, angle, 1.0)
        Imgproc.warpAffine(srcColor, rotated, rotMatrix, srcColor.size(), Imgproc.INTER_LINEAR)

        val outPath = imagePath.replace(".jpg", "_deskewed.jpg")
        Imgcodecs.imwrite(outPath, rotated)

        return outPath
    }

}
