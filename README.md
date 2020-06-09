# Gesture Control In 3 Dimensional Space
## Provisional grade is: A+ (estimated at or above 70%).

This project required me to fly a drone using movement gestures detected by an Apple Watch.
This was done by using a mixture of accelereometer/gyroscope/gravity readings, as well as a machine learning model trained to detect 'trick' commands that were used to make the drone do flips.

The motion data was used to create the general piloting control scheme based on the most current reading of the values.
The machine learning model was fed a larger set of readings that allowed for it to recognise movement over time, detect the movements completed, and send commands to the drone that correspond to the detected movements.

The machine learning model had a 96% accuracy after training and worked effectively for detecting different motions for front/back flips and left/right rolls.

Note that in the past I have worked with programmatic UI when using Swift. This project was a hybrid, with most of the work being completed programmatically. It does not use SwiftUI due to it being so new, I didn't want there to be any big changes to the language that would cause trouble during development so I stuck with UIKit/WatchKit.
