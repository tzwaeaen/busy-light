import time
import requests

time.sleep(45)

# Path to the binary file
status_file = "/piusb.bin"

# API URL
api_url = "http://localhost:5000/api/switch"

# Colors for different statuses
status_colors = {
    "busy": {"red": 255, "green": 0, "blue": 0},       # Red
    "away": {"red": 255, "green": 255, "blue": 0},     # Yellow
    "available": {"red": 0, "green": 255, "blue": 0},  # Green
    "dnd": {"red": 128, "green": 0, "blue": 128}       # Purple
}

# Function: Send a status to the API
def send_status_to_api(color, brightness=1):
    payload = {
        "red": color["red"],
        "green": color["green"],
        "blue": color["blue"],
        "brightness": brightness
    }

    try:
        # Make the API request
        response = requests.post(api_url, json=payload)
        if response.status_code == 200:
            print(f"Color set successfully: {color}, Brightness: {brightness}")
        else:
            print(f"Failed to set color. HTTP {response.status_code}: {response.                                                                                                                                                             text}")
    except Exception as e:
        print(f"Error sending request: {e}")

# Function: Read the status from the binary file
def read_status():
    try:
        with open(status_file, "rb") as f:  # Open in binary mode
            content = f.read()
            # Search for the string '#latestStatus='
            marker = b"#latestStatus="
            start = content.find(marker)
            if start != -1:
                start += len(marker)
                end = content.find(b"#", start)
                if end != -1:
                    # Extract and decode the status
                    return content[start:end].decode("utf-8").strip()
    except FileNotFoundError:
        print(f"File {status_file} not found.")
    except Exception as e:
        print(f"Error reading file: {e}")
    return None

# Main function
def main():
    # Initial API call to set the color to blue with brightness 0.2
    print("Setting initial color to blue with brightness 0.2")
    send_status_to_api({"red": 0, "green": 0, "blue": 255}, brightness=0.2)

    last_status = None
    while True:
        # Read the current status from the file
        current_status = read_status()

        # If the status has changed, send an API request
        if current_status and current_status != last_status:
            print(f"Status changed to: {current_status}")
            color = status_colors.get(current_status)
            if color:
                send_status_to_api(color)
            else:
                print(f"Unknown status: {current_status}")
            last_status = current_status

        # Wait for 5 seconds before checking again
        time.sleep(5)

if __name__ == "__main__":
    main()
