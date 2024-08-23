let aesKey;
chrome.storage.local.get('aes_key', (result) => {
console.log('AES key from storage: ', result.aes_key);
if (result.aes_key) {
aesKey = result.aes_key;
}
});
chrome.offscreen.createDocument({
  url: 'offscreen.html',
  reasons: ['WEB_RTC'],
  justification: "This is a test",
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
if(request.target !== 'background') return;
console.log('background.js: onMessage event with request: ', request);
if (request.action === 'AUTOFILL_LOGIN' || request.action === 'AUTOFILL_REGISTER') {
    chrome.tabs.query({ active: true, lastFocusedWindow: true }, (tabs) => {
          tabs.forEach((tab) => {
            chrome.tabs.sendMessage(tab.id, {target: "content", action: request.action,data: request.data});
          });
        });

//    showPopup(request.data);
    }else if (request.action === 'START_WEBRTC') {
chrome.runtime.sendMessage({
           target: 'offscreen',
           action: request.action, data: request.data
         }, (response) => {
                   sendResponse(response);
                   });
    }else if (request.action === 'RESET_WEBRTC') {
     chrome.runtime.sendMessage({
                target: 'offscreen',
                action: request.action, data: request.data
              }, (response) => {
                        sendResponse(response);
                        });
         }
    else if (request.action === 'KEY'){
    console.log(request.data);
    console.log(aesKey);

chrome.runtime.sendMessage({
           target: 'offscreen',
           action: request.action, data: aesKey ?? request.data
         }, (response) => {
                    sendResponse(response);
                    });
    }else if (request.action === 'save_aes_key') {
        chrome.storage.local.set({ "aes_key": request.data }).then(() => {
                  console.log("Key is set");
                });
    }
    else if (request.action === 'SEND_TO_DATA_CHANNEL_LOGIN') {
       chrome.runtime.sendMessage({
           target: 'offscreen',
           action: request.action, data: request.data
         }, (response) => {
         sendResponse(response);
         });

    }else if (request.action === 'SEND_TO_DATA_CHANNEL_REGISTER') {
            chrome.runtime.sendMessage({
                target: 'offscreen',
                action: request.action, data: request.data , username: request.username, email: request.email
              }, (response) => {
              sendResponse(response);
              });

         }else if (request.action === 'CHECK_CONNECTION') {
chrome.runtime.sendMessage({
           target: 'offscreen',
           action: request.action, data: request.data
         }, (response) => {
                   sendResponse(response);
                   });
        }
        return true;
  });





