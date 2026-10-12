import sys
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

chrome_options = Options()
chrome_options.binary_location = "/usr/bin/chromium"
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
driver = webdriver.Chrome(
    service=Service("/usr/bin/chromedriver"),
    options=chrome_options
)

url = "https://developers.google.com/android/images"

try:
    driver.get(url)

    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, "devsite-acknowledgement-link"))
        )
        ackButton = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, "devsite-acknowledgement-link"))
        )
        if (ackButton != None):
            ackButton.click()
            time.sleep(5)
    except:
        print("Did not find ack button", file=sys.stderr)
        pass

    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "husky"))
    )

except:
    print("Did not find husky table", file=sys.stderr)
    print("", end="")
    driver.quit()
    sys.exit(1)

soup = BeautifulSoup(driver.page_source, 'lxml')
table = soup.select_one('h2#husky').find_next('table')
lastRow = table.find_all('tr')[-1]
cells = lastRow.find_all(['td', 'th'])

# version, date, build ID - all from the first cell
firstColTxt = cells[0].text.strip()
firstColParts = firstColTxt.split(' ', 1)
version = firstColParts[0]
firstColTxt = firstColParts[1]
firstColTxt = firstColTxt.replace('(', '', 1).replace(',', '', 1).replace(')', '', 1)
firstColParts = firstColTxt.split(' ', 1)
buildId = firstColParts[0]
date = firstColParts[1]
# link at index 2 cell
link = cells[2].find("a")['href']
# sha is the last cells' text
sha = cells[3].text.strip()

driver.quit()

# return a text for the bash script
print(f"{version};{buildId};{date};{link};{sha}", end="")
