# PermissionController
The right way to ask about iOS permissions.
Currently supported are permissions for
 
* Location
* Calendar
* Notifications


![Screencast of the PermissionController on an iPhone](/Media/sample_video.gif?raw=true "Screencast of the PermissionController on an iPhone"  = 200px) 

##Benefits
As test have shown, the right time to ask about a permission is when the user wants to execute an action.
Due to the fact, that you only have one try to get the permission (iOS will not show the dialog again), you should pre-ask the user to grant it.

Using the **PermissionController**, it is easy for you as a developer to ask when the time is right. 
In addition to that, the user has to trigger the system dialog actively, what means that he already made the decision of agreeing with your request.

I have written down my thoughts on this topic in my [blog](https://anerma.de/blog).



##Installation
1. Import folder ```PermissionController``` into you project.

2. Import ```MapKit``` if you haven't already and provide strings in your ```info.plist```as needed.

3. There is no step three.


##Usage
Just call the method ```presentPermissionViewIfNeededInViewController(viewController: UIViewController, interestedInPermission: PermissionInterestedIn?, successBlock: (()->())?, failureBlock: (()->())? )``` passing your actual ```UIViewController```, the type of permission that you are interested in *(used to check if the desired permission was granted)* and what to do when the mentioned permission is granted (```successBlock```) or not (```failureBlock```).



##Related##
Please also take a look at my other projects, like [TTITransition](https://github.com/Tantalum73/TTITransition) or [GradientView](https://github.com/Tantalum73/GradientView).

**I wrote down my thoughts** concerning asking the user about permissions in detail on my [blog](https://anerma.de).


Also check out my app [TourTime](https://anerma.de/TourTime/), the app that measures the time you need to get from one location to another without draining your battery.

- [Website](https://anerma.de/TourTime/)
- [AppStore](https://itunes.apple.com/app/id848979893)


