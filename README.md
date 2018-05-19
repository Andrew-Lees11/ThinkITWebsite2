ThinkIT Website

Should be being hosted at [https://thinkitwebsite.eu-gb.mybluemix.net/](https://thinkitwebsite.eu-gb.mybluemix.net/)

Written using a [Kitura swift server](https://github.com/IBM-Swift/Kitura).

to run locally do the following in terminal:
```
git clone https://github.com/Andrew-Lees11/ThinkITWebsite.git
cd ThinkITWebsite/
brew install postgresql
swift build
.build/x86_64-apple-macosx10.10/debug/ThinkITWebsite
```

Then go to [http://localhost:8080/](http://localhost:8080/)

To view the server open the Xcodeproject

The webpages can be found in:

/Views: For html pages (called .stencil) which take variables from the server e.g. scores, donations
d
alldonations.stencil: served on [http://localhost:8080/alldonations](http://localhost:8080/alldonations) shows all the donations and i wasn't going to link from main webpage.

donator.stencil : served on [http://localhost:8080/donators?donator=exampledonator](http://localhost:8080/alldonations)

Shows your donations for the query donator

scores.stencil [http://localhost:8080/scores](http://localhost:8080/scores) shows the team scores

teams.stencil [http://localhost:8080/](http://localhost:8080/) dynamically shows teams but this could be made a static html since teams will not change

/Public: For static HTML pages which are served from /

E.g. the team pages and how to donate.
