# Apple Business Manager
My own take on a self-contained module for working with Apple Business Manager.

The goal is for the module to be:
* Cross platform
* Compatible with standard Windows PowerShell
* Self-contained (no external dependencies)
* Easy to use for PowerShell novices.  

### References
Apples official [Apple School and Business Manager APIs Documentation](https://developer.apple.com/documentation/apple-school-and-business-manager-api)

I also found these existing projects, which have inspired some of the code.
 * [PSABM](https://github.com/EUCTechTopics/PSABM)  
I like the file and folder structure and the module loading approach. I already did something similar, but this seems better.  
There's a lot of optimizations that I hadn't thought about before, that I really like.  
What I found was missing, was individual functions/Cmdlets, rather than just one to make the API calls.  
While I haven't tested it, the code also specifies a requirement for PowerShell 6+.

 * [ABMPS](https://scm.gruezi.net/buckbanzai/ABMPS)  
There's a lot of inspiration for me here, but it has external depency on jwtPS and PowerShell 6+ requirement.