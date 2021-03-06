# PermissionController
The right way to ask about iOS permissions.
Currently supported are permissions for
 
* Location
* Calendar
* Notifications


![Screencast of the PermissionController on an iPhone](/Media/sample_video.gif?raw=true "Screencast of the PermissionController on an iPhone"  = 150px) 

##Benefits
As test have shown, the right time to ask about a permission is when the user wants to execute an action.
Due to the fact, that you only have one try to get the permission (iOS will not show the dialog again), you should pre-ask the user to grant it.

Using the **PermissionController**, it is easy for you as a developer to ask when the time is right. 
In addition to that, the user has to trigger the system dialog actively, what means that he already made the decision of agreeing with your request.

In my [blog](https://anerma.de/blog), I posted some thougths about [how to ask the user about permissions](https://anerma.de/blog/asking-about-permissions) and also wrote some more about [this project and how to use it](https://anerma.de/blog/open-source-project-permissioncontroller).




##Installation
1. Import folder ```PermissionController``` into you project.

2. Import ```MapKit``` if you haven't already and provide strings in your ```info.plist```as needed.

3. There is no step three.


##Usage
Just call the method ```presentPermissionViewIfNeededInViewController(viewController: UIViewController, interestedInPermission: PermissionInterestedIn?, successBlock: (()->())?, failureBlock: (()->())? )``` passing your actual ```UIViewController```, the type of permission that you are interested in *(used to check if the desired permission was granted)* and what to do when the mentioned permission is granted (```successBlock```) or not (```failureBlock```).

**Also worth a note:**
If the user has declined, lets say the location permission, on a system level (by declining the system dialog question), PermissionController will open the device settings if the user hits the location button again.
This will enable the user to reconsider his decision.

##Related##
Please also take a look at my other projects, like [TTITransition](https://github.com/Tantalum73/TTITransition) or [GradientView](https://github.com/Tantalum73/GradientView).

**I wrote down my thoughts** concerning asking the user about permissions in detail on my [blog](https://anerma.de/blog/asking-about-permissions).
In addition to that, [here](https://anerma.de/blog/open-source-project-permissioncontroller) are some more words about this project.


Also check out my app [TourTime](https://anerma.de/TourTime/), the app that measures the time you need to get from one location to another without draining your battery.

- [Website](https://anerma.de/TourTime/)
- [AppStore](https://itunes.apple.com/app/id848979893)


