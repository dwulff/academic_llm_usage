import huggingface_hub
import PyPDF2
import os
import pandas as pd

client = huggingface_hub.InferenceClient(model = "meta-llama/Meta-Llama-3.1-405B-Instruct-FP8", token = "YOUR-HF-TOKEN")

articles = os.listdir("articles") 
names = [x.replace(".pdf","") for x in articles]

user = "Perform the following assessment steps.\n\Assessment 1: Assess if the article contains a original data analysis using LLMs.\n\nAssessment 2: Assess if the article's original data analysis uses large language models (LLMs).\n\nAssessment 3: Identify the names of the distinct LLMs used within the article's original data analysis. Mentions of LLMs in the context of referencing other articles do not count. Include the version in the LLMs name.\n\nBefore answering, reason step-by-step through the assessments. Only at the end and based on your reasoning, answer according to the following conditions.\n\nCondition 1: If Assessment 1 or 2 are false, strictly return LLMs=['none'].\nCondition 2: If Assessment 1 or 2 are true, return the list identified in Assessment 3 using the following format LLMs=[list of LLM names]."

# models = dict()
not_found = []
too_long = []
for name in names:
  if name in models.keys(): 
    continue
  try:
    reader = PyPDF2.PdfReader("articles/" + name + ".pdf")
  except:
    not_found.append(name)
    continue
  pages = [x.extract_text() for x in reader.pages]
  text = "\n".join(pages).replace("\n"," ")
  text = text[:min(45000, len(text))]
  system = "You are an expert on large language models (LLMs) who accurately assesses the following article:\n\n" + text
  prompt =f"<|begin_of_text|><|start_header_id|>system<|end_header_id|>{system}<|eot_id|><|start_header_id|>user<|end_header_id|>{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"
  try: 
    models[name] = client.text_generation(prompt, max_new_tokens = 1000)
  except:
    too_long.append(name)
    continue
  print(name + "\t" + str(len(models.keys())) + "\t" + models[name].replace("\n",""))


pd.DataFrame.from_dict(models, orient='index').to_csv("1_data/models_llama405.csv")
