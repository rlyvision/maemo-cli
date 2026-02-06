import argparse
import json

with open('data.json', 'r') as file:
    data = json.load(file)


def init():
    print("Available manufacturers:")
    for m in data["manufacturers"]:
        print(f"{m['id']}: {m['name']}")

# Step 2: Select manufacturer by ID
    manufacturer_input = input("\nSelect a manufacturer by ID: ").strip()
    if not manufacturer_input.isdigit():
        print("Invalid input.")
        init()
    manufacturer_id = int(manufacturer_input)

    selected_manufacturer = next((m for m in data["manufacturers"] if m["id"] == manufacturer_id), None)
    if not selected_manufacturer:
        print("Manufacturer not found.")
        exit()

# Step 3: List devices for the selected manufacturer
    print(f"\nDevices for {selected_manufacturer['name']}:")
    for d in selected_manufacturer["devices"]:
        print(f"{d['id']}: {d['name']}")

# Step 4: Select device by ID
    device_input = input("\nSelect a device by ID: ").strip()
    if not device_input.isdigit():
        print("Invalid input.")
        init()
    device_id = int(device_input)

    selected_device = next((d for d in selected_manufacturer["devices"] if d["id"] == device_id), None)
    if selected_device:
        print(f"\nYou selected: {selected_device['name']} from {selected_manufacturer['name']}")
    else:
        print("Device not found.")

def main():
    parser = argparse.ArgumentParser(
        description="maemo-cli (version v0.1)",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "-v", "--version",
        action="version",
        version="""maemo-cli v0.1\nMade by rlyvision""",
        help="Show program's version number and exit."
    )
    parser.add_argument(
        'command',
        choices=['init', 'install'],
        help="The command to execute"
    )

    args = parser.parse_args()

    if args.command == 'init':
        init()
    elif args.command == 'install':
        install()

if __name__ == "__main__":
    main()
