# Design of Visual Systems - Final Project
*Yujeong Seo, Gabriela Lee, 20 March 2026*

Link to lab logbooks: [🔗 Lab 5](/Lab5-Segmentation/README.md), [🔗 Lab 6](/Lab6-Classification/README.md)

## Project Overview

Overview of both challenges: maybe connect two somehow?

### Feature 1: Object Size Measurement

This program measure the physical dimensions of an object planced next to a standard credit card. The credit card serves as a fixed size reference, using its know dimensions of 85.6 × 54 mm.

**🌠 Image Processing**

Image is pre-processed using techniques learning in Labs: Contrast enhancement using `imadjust`, Gaussian filter to remove the noise, Otsu's method and morphological cleanups (`imopen`, `imclose`, `imfill`) to separate the objects from the background.

**💳 Credit Card Detection**

Connected regions are analysed using `regionprops` of `cc` element of the image. The card is identified by its aspect ratio with tolerance to slight distortion. 

**📏 Corner Detection and Straightening**

The card region is rotated using the `Orientation` property, and then mapped using Harris corner detection. Harris corner detection is applied and then four corners are selected geometrically from each quadrant. 

**🧸 Object Measurement**  

The remaining non-card region in the binarised image is taken as the object. The dimensions are converted to mm/cm metric, based on the mapped scale of credit card. Its bounding box dimension is derived from `MajorAxisLength` and `MinorAxisLength` on the straightened mask. Perimeter and area are measured directly from the binarised image. 

Full iterative processes can be accessed in `/Challenges/test` folder. 


### Feature 2: Artify Photographs

Description

## Setup & Requirements

**Required toolbox and equipment:** Image Processing Toolbox, Computer Vision Toolbox

* For the feature 1, run `main.m` in the `/Challenges/object-size-final` folder
* For the feature 2, 


## Results & Demonstrations

| Example 1        | Example 2      | 
| :---:             | :---:             | 
|![example-1](images/chall1-ex1.png) | ![example-2](images/chall1-ex2.png)|

The left image demonstrates the ability to suppress the light background noise and detect the card and the object. The right image demonstrates the **multi-object detection** and the ability to **handle the rotation**. More than one non-card objects are inspected using tabs on the right panel.

++ Feature 2 result and images


## Evaluations

### Feature 1 Evaluation

**Image correction:**
* Handles card rotation in any orientation wihtout manual input
* 🔺 Limitation on severely angled photographs. Attempt on homography extension as shown below, to be automatically applied when initial card detection fails. However, it generates unstable result, or misidentifies the card due to distorted ratio.

| Homography Attempt 1        | Homography Attempt 2      | 
| :---:             | :---:             | 
|![example-1](images/chall1-homo1.png) | ![example-2](images/chall1-homo2.png)|


**Environment dependencies:**
* Reliably detects a credit card and measures the object under controlled conditions: assumes well-lit image with clear background
* However, the performance would degrade on noisy, dark, or low-contrast backgrounds as Otsu's method might fail to separate objects cleanly


### Feature 2 Evaluation

Add description

## Individual Reflection

_Each member provides a person statement declaring what you personally have contributed to the project, a reflection section on what you have learned, reasons for your design decisions, mistakes you have made and what you would do differently if you were to do this again._

### Yujeong Seo:


### Gabriela Lee:
