from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time, math, random
import pandas as pd

def get_article_count(driver):
  html = driver.page_source
  soup = BeautifulSoup(html)
  count = soup.find('p', {'data-test-left-search-count': True})
  count = count.text.replace("\n","").lstrip().rstrip().replace(" results","")
  return(int(count))

def get_articles(driver):
  html = driver.page_source
  soup = BeautifulSoup(html)
  links = soup.find_all('a', {'data-test-search-result-card-title': True})
  articles = []
  for i in range(len(links)):
    entry = links[i].text.lstrip().rstrip()
    link = links[i]["href"]
    articles.append([entry, link])
  return(articles)

def sign_in(driver):
  element = driver.find_element(By.XPATH, '//button[text()="Sign In"]')
  element.click()
  element = driver.find_element(By.ID, 'username')
  element.send_keys("dirk.wulff@gmail.com")
  element = driver.find_element(By.ID, 'password')
  element.send_keys("ulrich84")
  element = driver.find_element(By.XPATH, '//button[@value="Sign in"]')
  element.click()

def sleep_long(): time.sleep(random.sample([3,5,7],1)[0])
  
def sleep_short(): time.sleep(random.sample([2,3,4],1)[0])

def run_keyword(keyword):
  page = f"https://osf.io/search?q={keyword}&resourceType=Preprint"
  driver = webdriver.Firefox()
  driver.get(page)
  sleep_short()
  sign_in(driver)
  sleep_short()
  count = get_article_count(driver)
  print(count)
  n_pages = math.ceil(count / 10) - 1
  articles = get_articles(driver)
  for i in range(n_pages):
    print(i)
    element = driver.find_element(By.XPATH, '//button[text()="Next"]')
    element.click()
    sleep_short()
    articles = articles + get_articles(driver)
    sleep_long()
  articles_df = pd.DataFrame(articles)
  articles_df.to_csv("1_data/article_info/articles_osf_" + str(keyword) + ".csv")


# RUN -----

keywords = ["%22large%20language%20model%22","%22large%20language%20models%22","%22llm%22","%22llms%22","%22AI%22","%22artificial intelligence%22"]
for key in keywords: run_keyword(key)  

