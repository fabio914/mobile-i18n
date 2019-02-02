package com.example.localization

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.appcompat.app.AlertDialog
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        actionButton.setOnClickListener {
            val name = textInput.text.toString()

            if (name.isNotEmpty()) {

                val namespace = LocalizedStrings.hello

                AlertDialog.Builder(this)
                    .setTitle(namespace.title)
                    .setMessage(namespace.message(name = name))
                    .setPositiveButton(namespace.done) { _, _ -> }
                    .create()
                    .show()
            }
        }
    }
}
