
import os
from google import genai
from dotenv import load_dotenv

load_dotenv(override=True)

def list_models_check():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("No API Key")
        return

    client = genai.Client(api_key=api_key)
    try:
        print("Listing available models...")
        # Note: The new SDK syntax for listing models might differ slightly or require a pager
        # But let's try the basic call
        for m in client.models.list(config={"page_size": 100}):
            print(f"Model: {m.name}")
    except Exception as e:
        print(f"Error listing models: {e}")

if __name__ == "__main__":
    list_models_check()
