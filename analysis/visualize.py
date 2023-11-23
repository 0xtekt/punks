from PIL import Image
import numpy as np

def hex_to_image(hex_data):
    # Remove: '0x' prefixes
    hex_data = hex_data.replace('0x', '')

    # Convert: hex to byte array
    byte_data = bytes.fromhex(hex_data)

    # Convert: byte array to numpy array
    img_data = np.frombuffer(byte_data, dtype=np.uint8)

    # Create image
    return Image.frombuffer('RGBA', (24, 24), img_data, 'raw', 'RGBA', 0, 1)

def main():
    images = []

    # Read: hex data from file
    with open('./analysis/output.txt', 'r') as file:
        for line in file:
            img = hex_to_image(line.strip())

            # Resize image
            scale_factor = 12
            new_size = (24 * scale_factor, 24 * scale_factor)
            resized_img = img.resize(new_size, Image.NEAREST)
            images.append(resized_img)

    # Combine images side by side
    total_width = new_size[0] * len(images)
    combined_image = Image.new('RGBA', (total_width, new_size[1]))

    x_offset = 0
    for img in images:
        combined_image.paste(img, (x_offset, 0))
        x_offset += img.width

    # Display the combined image
    combined_image.show()

if __name__ == "__main__":
    main()
