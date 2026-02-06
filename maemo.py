import argparse
import json
import os
import subprocess
import sys
import os

DATA_FILE = "/tmp/maemo_selected_device.txt"

with open('data.json', 'r') as file:
    data = json.load(file)


def load_previous():
    previous = {}

    if not os.path.exists(DATA_FILE):
        previous["manufacturer_id"] = "2"      
        previous["manufacturer_name"] = "Nokia"
        previous["device_id"] = "2"             
        previous["device_name"] = "Nokia N900"
        return previous

    with open(DATA_FILE) as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                previous[k] = v

    return previous


def save_selection(manufacturer, device):
    with open(DATA_FILE, "w") as f:
        f.write(f"manufacturer_id={manufacturer['id']}\n")
        f.write(f"manufacturer_name={manufacturer['name']}\n")
        f.write(f"device_id={device['id']}\n")
        f.write(f"device_name={device['name']}\n")


def select():
    previous = load_previous()


    while True:
        print("Available manufacturers:")
        for m in data["manufacturers"]:
            default = " (default)" if str(m["id"]) == previous.get("manufacturer_id") else ""
            print(f"{m['id']}: {m['name']}{default}")

        default_id = previous.get("manufacturer_id", "")
        manufacturer_input = input(
            f"\nSelect a manufacturer by ID [{default_id}]: "
        ).strip()

        manufacturer_input = manufacturer_input or default_id
        if not manufacturer_input.isdigit():
            print("Invalid input.\n")
            continue

        manufacturer_id = int(manufacturer_input)
        selected_manufacturer = next(
            (m for m in data["manufacturers"] if m["id"] == manufacturer_id), None
        )

        if not selected_manufacturer:
            print("Manufacturer not found.\n")
            continue

        break

    while True:
        print(f"\nDevices for {selected_manufacturer['name']}:")
        for d in selected_manufacturer["devices"]:
            default = " (default)" if str(d["id"]) == previous.get("device_id") else ""
            print(f"{d['id']}: {d['name']}{default}")

        default_device = previous.get("device_id", "")
        device_input = input(
            f"\nSelect a device by ID [{default_device}]: "
        ).strip()

        device_input = device_input or default_device
        if not device_input.isdigit():
            print("Invalid input.\n")
            continue

        device_id = int(device_input)
        selected_device = next(
            (d for d in selected_manufacturer["devices"] if d["id"] == device_id), None
        )

        if not selected_device:
            print("Device not found.\n")
            continue

        break


    save_selection(selected_manufacturer, selected_device)

    check = str(input(f"\nYou selected: {selected_device['name']}, Is that correct [Y/N]: "))
    if check == "Y":
        pass
    if check == "N":
        print("Select Again")
        select()
    

def install():
    if not os.path.exists(DATA_FILE):
        print("No device selected. Run `init` first.")
        sys.exit(1)

    # Load saved selection
    selected = {}
    with open(DATA_FILE) as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                selected[k] = v

    manufacturer_id = selected["manufacturer_id"]
    device_id = selected["device_id"]

    # Build script path based on IDs
    script_path = f"scripts/{manufacturer_id}-{device_id}.sh"

    if not os.path.isfile(script_path):
        print(f"Install script not found: {script_path}")
        sys.exit(1)

    try:
        subprocess.run(
            ["bash", script_path],
            check=True
        )
    except subprocess.CalledProcessError:
        print("Install script failed.")
        sys.exit(1)



def main():
    parser = argparse.ArgumentParser(
        description="maemo-cli (version v0.1)",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "-v", "--version",
        action="version",
        version="maemo-cli v0.1\nMade by rlyvision",
        help="Show program's version number and exit."
    )

    parser.add_argument(
        'command',
        choices=['select', 'install'],
        help="The command to execute"
    )

    args = parser.parse_args()

    if args.command == 'select':
        select()
    elif args.command == 'install':
        install()


if __name__ == "__main__":
    main()
