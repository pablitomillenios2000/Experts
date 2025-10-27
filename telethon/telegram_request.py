from telethon.sync import TelegramClient
from telethon.errors import SessionPasswordNeededError
import json5

# Load configuration from user.json5
with open('user.json5', 'r') as f:
    config = json5.load(f)

# Extract values
api_id = config['api_id']
api_hash = config['api_hash']
phone = config['phone']
channel = config['channel']

# Initialize client
client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start(phone=phone)  # Authenticates; enter code (and 2FA password if enabled) on first run
    
    # Fetch last 10 messages
    async for message in client.iter_messages(channel, limit=10):
        print(f"Message ID: {message.id}")
        print(f"Date: {message.date}")
        print(f"Text: {message.text}\n" if message.text else "No text (e.g., media only)\n")

with client:
    client.loop.run_until_complete(main())