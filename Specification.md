# PhotoRename

Write an application for MacOS

## Style Guide

Follow the following as the style guid.

https://google.github.io/swift/#source-file-structure

# PhotoRename
Write an application for MacOS using Swift.

This application is meant to pre-pend the name of the file with the date when the picture or movie was taken using the exif data that exists in the file.

The application is meant to be an UI application.

The application should be able to select a folder from any attached storage device.  The user should also be able to select if they want to do a recursive search of the folder or just the top folder.

The results should be added to a list box type window.  

* The name of the file.
* The date the file was created
* The date the file the picture or movie was taken from the exif data.

The list box should have the capability to select a number of files and then click a button or use a context menu that renames the files.  

After the files are renamed, they should show green or use an icon in the list if it was successfully renamed.  They should show as Red or a failure icon if they were not able to be renamed.

Meta data should be saved for both the successful and failed renames. so we could do a undo

For the successful, we should store the original name of the file as well as the exif date that was used and the create date.

There should be a text box that allows the user to select a folder where the file should be copied and renamed in that location, this way the original location does not change.

The name of the file will be renamed from `[FileName]` to `yyyy_MMdd_HHmmss_[FileName].extension`.

The state should be saved so when the application is opened and re-opened the original state can be loaded.

The application should have a function of workspaces.  This way the user can save off a workspace and have multiple workspaces.


There should be undo and redo feature.  IE when a file has been renamed, we should be able to undo that change.  Also we should be able to redo that undo if we want.

The selection should also allow

Add a Yes or No type field that says that the file either has location data or not.

## Renaming the file

When renaming the file, the name of the file should go from `[FileName]` to `yyyy_MMdd_HHmmss_[FileName].extension`.

The change should be remembered.  The old name should be cached away so the user can do an undo and also be able to do a redo if necessary.

When the rename on the file occurs it should be reflected in the UI in the list.

## Selected map pane

In the map pane, the user should be able to zoom out and into the pin where the picture was taken.

For static images, we should be able to get the information from exif information.

Form movies we should be able to get that information 

## Application layout

The main app page should be laid out with the following.

Left side should be the list of files found in the folder that was selected.

Right side should be two preview windows, one sitting on top of another.

The top window should show a preview of the image that is selected.  If multiple files are selected, then a navigation button should be added so you can move through the selected images.

The bottom window should show a preview of where the image was taken.  If multiple files are selected, then each of them should be shown on the map.


## Map data

We should also have the ability to update or add map data.

If the user wants to add map data, they should be able to right click the image or images and then say change location data and a map is popped up and the user can type in a location or navigate to the location and drop a pin.  That pin location will be the new location data.

If an image is incapable of storing location data, then it should be marked as such.

## Workspace

The purpose of workspaces is to remember all the settings that were set along with remembering all the commands and changes that were made as a part of that workspaces.

It should track any settings, like what folder is being renamed or if it is being renamed in place or in a different folder.

It should track any files that were renamed.

This way the user can make different changes across different workspaces.


This application is meant to have a user interface where we can point it to a folder.  There should be a selection that does a recursive run through the folder.

In that folder it should show all files that are images and or movies.

They should be listed in a list box with the name of the file along with the date and time the picture was created.

Another column should be the date and time from the exif data.
This application will run on macos it will have a UI and will use Swift as the lanugage.

Give the user the ability to select a folder.  The user will have the option to set if they wish to do a recursive folder search.

Results found in the selected folder and the children folders should be showed in a list that has the following information:

**File Name**

Just the name of the file and the extension of the file.

**Path**

The path starting from the root of parent.  So `.` for parent and `./child` for children paths.  If the path is too long to show in the UI, use a tool tip that when the user hovers over the path the user can see the full path in the tool tip.

**Current Date and Time**

The current date and time with the following format yyyyMMdd-HHmmss.



The results found should show up in the UI and you should be able to scroll and see each item found.  

The application needs to be able to handle over 30,000 individual items.

When an item is selected, we should be able to see a preview of the image or a thumbnail of the video.

There should be a column on the left side that shows the status of the rename or copy to a name or an error.  Some type of icon Green all good, yellow some type of warning and red for something went wrong.

|Field Name|Purpose|
|----------|-------|
|File Name||

File Name | Original Date |  

Files that are not supported by t


For files that are to be skipped, they should show greyed out so they are disabled.

These are the following file extensions that we support.

We should list 

On the side I'd like to show a preview of the picture or move and under it the a map with where it was taken.
Also show the exif data

What can I say?


The location where we list the app

This app should have a place where it lists what it found in the folders in the UI.

The UI should have the f

The user should be able to select all items.  They should be able to use control to deselect items.


Write a macos application using swift UI that lists the contents of a folder in a list.  For files that are images or movies, if they are selected, they should show an image preview in a side bar.  If the image or movie has location information, a map showing where the picture was taken should show up under the UI preview.