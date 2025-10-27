from telethon.sync import TelegramClient
from telethon.errors import SessionPasswordNeededError
import json5
import os

# Create media folder for potential downloads
if not os.path.exists('media'):
    os.makedirs('media')

# Load configuration from user.json5
with open('user.json5', 'r') as f:
    config = json5.load(f)

# Extract values
api_id = config['api_id']
api_hash = config['api_hash']
phone = config['phone']
channel = config['channel']  # Should be "-1001489499975"

# Initialize client
client = TelegramClient('session_name', api_id, api_hash)

async def main():
    try:
        await client.start(phone=phone)
        # Verify channel
        entity = await client.get_entity(channel)
        print(f"Reading messages from: {entity.title} (ID: {channel})")
        # Fetch last 10 messages
        async for message in client.iter_messages(channel, limit=10):
            print(f"Message ID: {message.id}")
            print(f"Date: {message.date}")
            if message.text:
                print(f"Text: {message.text}")
            if message.media:
                print(f"Media: {type(message.media).__name__}")
                # Download media (optional)
                if hasattr(message.media, 'document') or hasattr(message.media, 'photo'):
                    await message.download_media(file=f"media/{message.id}")
            print()
    except Exception as e:
        print(f"Error: {e}")

with client:
    client.loop.run_until_complete(main())