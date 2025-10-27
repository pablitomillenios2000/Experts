from telethon.sync import TelegramClient
from telethon.errors import SessionPasswordNeededError
import json5
import os
import pandas as pd
from datetime import datetime, timedelta
import asyncio

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

        # Calculate time range (last 5 days)
        time_threshold = datetime.now() - timedelta(days=5)

        # Prepare data for CSV
        messages_data = []

        # Fetch messages containing "Compro TSLA" within the last 5 days
        async for message in client.iter_messages(channel, search="Compro TSLA"):
            if message.date.replace(tzinfo=None) < time_threshold:
                break  # Stop if message is older than 5 days
            if message.text and "Compro TSLA" in message.text:
                message_info = {
                    'message_id': message.id,
                    'date': message.date,
                    'text': message.text,
                    'media': type(message.media).__name__ if message.media else None
                }
                messages_data.append(message_info)
                print(f"Found message ID: {message.id}, Date: {message.date}")

                # Download media (optional)
                if message.media and (hasattr(message.media, 'document') or hasattr(message.media, 'photo')):
                    await message.download_media(file=f"media/{message.id}")

        # Save to CSV
        if messages_data:
            df = pd.DataFrame(messages_data)
            df.to_csv('compro_tsla_5d.csv', index=False, encoding='utf-8')
            print(f"Saved {len(messages_data)} messages to compro_tsla_5d.csv")
        else:
            print("No messages found with 'Compro TSLA' in the last 5 days")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        await client.disconnect()  # Ensure disconnection to avoid session issues

# Run the script
with client:
    client.loop.run_until_complete(main())