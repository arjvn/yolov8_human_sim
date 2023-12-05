import json
import cv2
import os
from tqdm import tqdm
import random
import glob
import argparse

# Create a function to convert bounding box coordinates to normalized xywh format
def convert_bbox_to_yolo(bbox, image_width, image_height):
    x, y, width, height = bbox
    x_center = (x + width / 2) / image_width
    y_center = (y + height / 2) / image_height
    yolo_width = width / image_width
    yolo_height = height / image_height
    return x_center, y_center, yolo_width, yolo_height


def split_dataset(dataset_name):
    # random split the dataset into train and val - 80:20
    images_list = glob.glob(f"datasets/{dataset_name}/images/*.png")
    random.shuffle(images_list)
    split = int(0.8 * len(images_list))
    train_images = images_list[:split]
    val_images = images_list[split:]
    # move images and labels to train and val folders
    if not os.path.exists(f"datasets/{dataset_name}/images/train"):
        os.makedirs(f"datasets/{dataset_name}/images/train")
        os.makedirs(f"datasets/{dataset_name}/labels/train")
        os.makedirs(f"datasets/{dataset_name}/images/val")
        os.makedirs(f"datasets/{dataset_name}/labels/val")
    for tr_img in train_images:
        os.system(f"mv {tr_img} datasets/{dataset_name}/images/train")
        os.system(f"mv {tr_img.replace('images', 'labels').replace('.png', '.txt')} datasets/{dataset_name}/labels/train")
    for val_img in val_images:
        os.system(f"mv {val_img} datasets/{dataset_name}/images/val")
        os.system(f"mv {val_img.replace('images', 'labels').replace('.png', '.txt')} datasets/{dataset_name}/labels/val")


if __name__ == '__main__':
   
    parser = argparse.ArgumentParser(description='Create YOLO labels')
    parser.add_argument('--dataset_name', type=str, default='peoplesanspeople', help='Name of the dataset')
    args = parser.parse_args()
    

    # Load the JSON file
    dataset_name = args.dataset_name
    root_path = f'PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1/'

    directories = [d for d in os.listdir(root_path) if os.path.isdir(os.path.join(root_path, d))]
    rgb_directory = next((d for d in directories if d.startswith("RGB")), None)
    dataset_directory = next((d for d in directories if d.startswith("Dataset")), None)
    print(f"rgb_directory: {rgb_directory}")
    print(f"dataset_directory: {dataset_directory}")
    json_path = f'PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1/{dataset_directory}/captures_000.json'
    images_path = os.path.join(root_path, rgb_directory)
    labels_path = os.path.join(root_path, 'labels')


    # copy images folder to database/peoplesanspeople/images all parent folders must exist else creatre them
    if not os.path.exists(f"datasets/{dataset_name}/images"):
        os.makedirs(f"datasets/{dataset_name}/images")
    os.system(f"cp -r {images_path}/* datasets/{dataset_name}/images")
    images_path = f"datasets/{dataset_name}/images"

    # create folder for txt files
    if not os.path.exists(f"datasets/{dataset_name}/labels"):
        os.makedirs(f"datasets/{dataset_name}/labels")
    labels_path = f"datasets/{dataset_name}/labels"

    # open annotations provided by unity
    with open(json_path) as file:
        data = json.load(file)

    # Loop through the captures key
    yolo_annotations = []
    images = {}  # Create an empty dictionary for images
    annotation_id = 0

    # Loop through the captures key
    for capture in tqdm(data['captures']):
        image_name = capture['filename'].split('/')[-1].split('.')[0]
        image_path = os.path.join(images_path, image_name + '.png')
        # make sure image can be read   
        image = cv2.imread(image_path)
        if image is None:
            print(f" 🐛 Could not read image {image_path}")
            continue
        image_height, image_width, _ = image.shape
        
        # Create a .txt file with the same name as the image file
        label_file_path = os.path.join(labels_path, image_name + '.txt')
        with open(label_file_path, 'w') as txt_file:
            for annotation in capture['annotations'][0]['values']:
                category_id = annotation['label_id']-1
                bbox = [int(annotation['x']), int(annotation['y']), int(annotation['width']), int(annotation['height'])]
                x_center, y_center, yolo_width, yolo_height = convert_bbox_to_yolo(bbox, image_width, image_height)
                txt_file.write(f"{category_id} {x_center} {y_center} {yolo_width} {yolo_height}\n")


    split_dataset(dataset_name)

    # create .yaml file for the dataset
    dataset_yaml_path = "yolov8/data/"
    if not os.path.exists(dataset_yaml_path):
        os.makedirs(dataset_yaml_path)
    with open(dataset_yaml_path+f'{dataset_name}.yaml', "w") as yaml_file:
        yaml_file.write(f"path: /usr/src/app/datasets/{dataset_name}\n")
        yaml_file.write("train: ../images/train\n")
        yaml_file.write("val: ../images/val\n")
        yaml_file.write("names:\n")
        yaml_file.write(f"  0: {annotation['label_name']}\n")