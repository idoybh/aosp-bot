import sys
import time
from selenium import webdriver
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
driver = webdriver.Chrome(options=chrome_options)

url = "https://source.android.com/docs/setup/reference/build-numbers"

try:
    driver.get(url)
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.ID, "source-code-tags-and-builds"))
    )

except:
    print("Did not find builds table", file=sys.stderr)
    print("", end="")
    driver.quit()
    sys.exit(1)

soup = BeautifulSoup(driver.page_source, 'lxml')
table = soup.select_one('h2#source-code-tags-and-builds').find_next('table')
firstRow = table.find_all('tr')[1] # index 0 is the title
cells = firstRow.find_all(['td', 'th'])

# build ID at first cell
buildId = cells[0].text.strip()
# tag at 2nd cell
tag = cells[1].text.strip()
# patch level at last cell
patch = cells[-1].text.strip()

driver.quit()

# return a text for the bash script
print(f"{buildId};{tag};{patch}", end="")
