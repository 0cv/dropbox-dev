global with sharing class myRewriter implements Site.UrlRewriter {

    global PageReference mapRequestUrl(PageReference myFriendlyUrl){
         String myURL = myFriendlyUrl.getURL();
         //if(myURL.contains('apex/')) {
             return myFriendlyUrl;
        // }
        // else {
        //     return new PageReference('/apex/mainPage');
        // }
    }
    global List<PageReference> generateUrlFor(List<PageReference> 
            mySalesforceUrls){
        return mySalesforceUrls;
  }

}