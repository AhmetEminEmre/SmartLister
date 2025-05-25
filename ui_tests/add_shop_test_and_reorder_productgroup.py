import uiautomator2 as u2
import time

d = u2.connect()

try:
    print("Starting test...")

    package_name = "com.example.smart"

    d.app_stop(package_name)
    print("App stopped")

    time.sleep(3)

    d.app_start(package_name)
    print("App started successfully.")

    time.sleep(4)

    if d(description="Neuen Laden erstellen").exists(timeout=10):
        d(description="Neuen Laden erstellen").click()
        print("Button 'Create New Store' clicked successfully.")
    else:
        print("Button 'Create New Store' not found.")
        exit()

    time.sleep(4)

    if d(className="android.widget.EditText").exists(timeout=5):
        d(className="android.widget.EditText").click()
        time.sleep(2)  
        d(className="android.widget.EditText").send_keys("Billa YY")
        print("Store name 'Billa X1' entered successfully.")
    else:
        print("Text field for store name not found.")
        exit()

    time.sleep(4)

    if d(description="Laden hinzufügen").exists(timeout=5):
        d(description="Laden hinzufügen").click()
        print("Button 'Add Store' clicked successfully.")
    else:
        print("Button 'Add Store' not found.")
        exit()

    time.sleep(4)

    if d(description="Ja").exists(timeout=5):
        d(description="Ja").click()
        print("'Yes' in the dialog clicked successfully.")
        time.sleep(4)
    else:
        print("Option 'Yes' in the dialog not found.")
        exit()

    if d(description="Fischprodukte").exists(timeout=5):
        d(description="Fischprodukte").drag_to(0, 0)
        print("'Fischprodukte' moved to the top.")
    else:
        print("'Fischprodukte' not found.")
        exit()

    time.sleep(4)

    if d(description="Obst & Gemüse").exists(timeout=5):
        saefte = d(description="Säfte")
        fleisch = d(description="Fleisch")
        if saefte.exists and fleisch.exists:
            saefte_bounds = saefte.info['bounds']
            fleisch_bounds = fleisch.info['bounds']
            
            print(f"'Säfte' bounds: {saefte_bounds}")
            print(f"'Fleisch' bounds: {fleisch_bounds}")

            target_x = (saefte_bounds['left'] + saefte_bounds['right']) // 2
            target_y = (saefte_bounds['bottom'] + fleisch_bounds['top']) // 2 - 10
            
            print(f"Calculated target position: x={target_x}, y={target_y}")
            
            d(description="Obst & Gemüse").drag_to(target_x, target_y)
            print("'Obst & Gemüse' moved between 'Säfte' and 'Fleisch'.")
            time.sleep(4)
        else:
            print("'Säfte' or 'Fleisch' not found.")
    else:
        print("'Obst & Gemüse' not found.")
        exit()

except Exception as e:
    print(f"Error: {e}")

finally:
    d.app_stop(package_name)
    print("Test completed.")
