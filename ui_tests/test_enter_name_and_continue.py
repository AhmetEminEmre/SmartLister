import unittest
import time
from appium import webdriver
from appium.options.common import AppiumOptions

capabilities = {
    "platformName": "Android",
    "automationName": "Flutter",
    "deviceName": "emulator-5554",
    "app": "build/app/outputs/flutter-apk/app-debug.apk"
}

appium_server_url = 'http://localhost:4723'

class TestSmartLister(unittest.TestCase):
    def setUp(self) -> None:
        options = AppiumOptions().load_capabilities(capabilities)
        self.driver = webdriver.Remote(appium_server_url, options=options)

    def tearDown(self) -> None:
        if self.driver:
            self.driver.quit()

    def test_enter_nickname(self):
        self.driver.execute_script('flutter:waitFor', {
            'finderType': 'byValueKey',
            'keyValueString': 'nicknameField',
        })

        self.driver.execute_script('flutter:enterText', {
            'finderType': 'byValueKey',
            'keyValueString': 'nicknameField',
            'text': 'Tester',
        })

        time.sleep(3)

        self.driver.execute_script('flutter:tap', {
            'finderType': 'byValueKey',
            'keyValueString': 'continueButton',
        })

        time.sleep(3)
        print("✅ Name eingegeben und Button gedrückt")

if __name__ == '__main__':
    unittest.main()
