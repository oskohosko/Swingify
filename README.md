# Swingify

A Golf App I created that shows the hole you are playing, displays distances and projects a 10% dispersion onto the map for each club in your bag.

# Functionalities

## Select Club
Can add clubs and their distance to your bag.
When on the course, you can select from a drop down and choose a club.
A 10% dispersion based on the distance of the club will be displayed originally in the direction of the green.
You can double tap anywhere on the map while the dispersion is displayed to change its direction.
A single tap on the dispersion ring will display the distance for a brief period of time.

## Distances
Holding down on a position on the map will place a pin and a distance to that pin from your location.
If location hasn't been approved, the teebox is the location the distance is measured from.
Simply tap the pin to remove it from the map.

## Elevation Adjustment
A toggleable elevation switch will generate adjusted distances which take elevation into account.
Uphill = Longer, Downhill = Shorter.

## Home Course and Favourites
You can select your home course on your profile and save courses to your favourites to save time when navigating to the course you are playing.


# Screenshots
<p>
  <img src="/Screenshots/royalmelb.PNG" width=240 alt="Par 3 Screenshot">
  <img src="/Screenshots/rosebud12.PNG" width=240 alt="Par 4 Screenshot">
  <img src="/Screenshots/tulla.PNG" width=240 alt="Par 4 Screenshot">
  <img src="/Screenshots/rosebud13.PNG" width=240 alt="Par 3 Screenshot">
</p>

## In Progress
Working on a watchOS app to display distances and automatically track my round by detecting swings and logging locations of them to the cloud. 
Am also planning to improve the iOS app once the watchOS app and Web app are up and running.

# WatchOS App

<p>
  <img src="/Screenshots/watchOS.PNG" width=240 alt="watchOS screenshot">
</p>

## Overview
Implementing a watchOS app to complement my iOS app. It will display distances, point to the center of the green, track rounds, detect shots and save them to the cloud for analysis on a web application.
The ultimate goal is to be able to automatically have my golf rounds tracked and to visualise where I took each shot from after the round, as well as share it with others.

# Features

## Distance Display
Displays the distance from the user to the center of the green. If the user doesn't allow location tracking, it uses the distance from the tee.

## Green Compass
A compass feature that points in the direction of the center of the green. Since I spend a lot of time on other fairways, this is useful to have as I often can't see where I'm hitting to.

## Shot Saving
Currently, my app saves round data to Firebase. It doesn't do this automatically yet, but saves rounds, and for each round saves holes with each hole containing a series of shots I took.
The data saved includes coordinates and distances.

## In progress
I'm currently implementing the round tracking system which will utilise swing detection logic using the accelerometer and gyroscope as well as geofencing to detect when the user goes to the next hole.

## Plans
I'm planning to connect all of these with a web application and to create an authentication system that can be used between the three applications.



