
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
if(request.target !== 'offscreen') return;
console.log('offscreen.js: onMessage event with request: ', request);
    if (request.action === 'AUTOFILL_PASSWORD') {
//    showPopup(request.data);
    }else if (request.action === 'START_WEBRTC') {
    if(!socket && !localDataChannel){
    connectToSignalingServer();
    }else{
    sendResponse(JSON.stringify({connection: 1}));
    console.log('WebRTC already started');
    }
    }else if (request.action === 'RESET_WEBRTC') {
        reconnectPeerConnection();
         }else if (request.action === 'KEY'){
    console.log(request);
    if(!aesKey){
     aesKey = importKey(request.data);
     aesKeyString = request.data;
    sendResponse({ response: 'Key received' });
    }else{
    console.log('Key already exists');
    }
    }else if (request.action === 'SEND_TO_DATA_CHANNEL_LOGIN' || request.action === 'SEND_TO_DATA_CHANNEL_REGISTER') {
        sendToDataChannel(request);
        sendResponse({ response: 'Message sent' });
    }else if (request.action === 'CHECK_CONNECTION') {
        if(socket && localDataChannel){
    sendResponse(JSON.stringify({connection: 1}));
        }else{
    sendResponse(JSON.stringify({connection: 0}));
        }
        }
        return true;
  });


let aesKey;
let aesKeyString;
let localPeerConnection;
let remotePeerConnection;
let localDataChannel;
let remoteDataChannel;
let socket;
const peerConnectionConfig = {
    'iceServers': [
      {'urls': 'stun:stun.stunprotocol.org:3478'},
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  // Connect to the signaling server
    function connectToSignalingServer() {
      socket = new WebSocket('wss://der1.ezas.org:8080');

      socket.onopen = () => {
        console.log('Connected to the signaling server');
       return startWebRTC();
      };

      socket.onmessage = (message) => {
        const data = JSON.parse(message.data);
        handleSignalingData(data);
      };

      socket.onerror = (error) => {
        console.error('WebSocket error:', error);
      };

      socket.onclose = () => {
        console.log('WebSocket connection closed');
      };
    }

    // Handle signaling data received from the server
    function handleSignalingData(data) {
      if (data.type === 'offer') {
        handleOffer(data.offer);
      } else if (data.type === 'answer') {
        handleAnswer(data.answer);
      } else if (data.type === 'candidate') {
        handleCandidate(data.candidate);
      }
    }

    // Create an offer and send it to the signaling server
    function startWebRTC() {
    if(localPeerConnection && localDataChannel) return;
      localPeerConnection = new RTCPeerConnection(peerConnectionConfig);

      // Create a data channel
      localDataChannel = localPeerConnection.createDataChannel('textChannel');


    localPeerConnection.oniceconnectionstatechange = () =>{
            console.log('WebRTC connection state:', localPeerConnection.iceConnectionState);

     if(localPeerConnection.iceConnectionState == 'disconnected') {
         resetProperties()
     }
    };
     localPeerConnection.onconnectionstatechange = () => {
        if (localPeerConnection.connectionState === 'disconnected' ||
            localPeerConnection.connectionState === 'failed' ||
            localPeerConnection.connectionState === 'closed') {
          console.log('WebRTC connection state:', localPeerConnection.connectionState);
          chrome.runtime.sendMessage(JSON.stringify({connection: 0}));
          resetProperties()

        }
      };

      localDataChannel.onopen = () => {
      console.log('Data channel is open');
      chrome.runtime.sendMessage({target: "background", action: 'save_aes_key', data: aesKeyString});
      chrome.runtime.sendMessage(JSON.stringify({connection: 1}));
      };

      localDataChannel.onmessage = (event) => {
      const decryptedData = decryptData(event.data).then((decrypted) => {
      const jsonData = JSON.parse(decrypted);
      const entries = JSON.parse(jsonData.data).map(data => JSON.parse(data));
      chrome.runtime.sendMessage({target: "background", action: jsonData.action,data: entries});
      console.log('Received message:', jsonData);
      }).catch((error) => {

      });

      };

      localPeerConnection.onicecandidate = (event) => {
        if (event.candidate) {
          sendToSignalingServer({ type: 'candidate', candidate: event.candidate });
        }
      };

      localPeerConnection.createOffer()
        .then((offer) => {
          return localPeerConnection.setLocalDescription(offer);
        })
        .then(() => {
          sendToSignalingServer({ type: 'offer', offer: localPeerConnection.localDescription });
        })
        .catch((error) => {
          console.error('Error creating offer:', error);
        });
        if(localDataChannel.readyState !== 'open'){
        return 0;
        }
        return 1;
    }

    function resetProperties(){
//    aesKey = null;
    localPeerConnection= undefined;
    remotePeerConnection= undefined;
    localDataChannel= undefined;
    remoteDataChannel= undefined;
    socket= undefined;
    }

    // Disconnect the WebRTC connection
    function disconnectPeerConnection() {
    if (socket) {
        socket.close();
      }
      if (localPeerConnection) {
        // Close the data channel if it exists
        if (localDataChannel) {
          localDataChannel.close();
        }

        // Close the peer connection
        localPeerConnection.close();
      chrome.runtime.sendMessage(JSON.stringify({connection: 0}));

        resetProperties();
      }
    }

    // Reconnect the WebRTC connection
    async function reconnectPeerConnection() {
      disconnectPeerConnection();
      await connectToSignalingServer();
    }


    // Handle offer from remote peer
    function handleOffer(offer) {
      remotePeerConnection = new RTCPeerConnection(peerConnectionConfig);

      remotePeerConnection.ondatachannel = (event) => {
        remoteDataChannel = event.channel;

        remoteDataChannel.onmessage = (event) => {
          console.log('Received message on remote data channel:', event.data);
        };

        remoteDataChannel.onopen = () => {
          console.log('Remote data channel is open');
        };
      };

      remotePeerConnection.onicecandidate = (event) => {
        if (event.candidate) {
          sendToSignalingServer({ type: 'candidate', candidate: event.candidate });
        }
      };

      remotePeerConnection.setRemoteDescription(new RTCSessionDescription(offer))
        .then(() => {
          return remotePeerConnection.createAnswer();
        })
        .then((answer) => {
          return remotePeerConnection.setLocalDescription(answer);
        })
        .then(() => {
          sendToSignalingServer({ type: 'answer', answer: remotePeerConnection.localDescription });
        })
        .catch((error) => {
          console.error('Error handling offer:', error);
        });
    }

    // Handle answer from remote peer
    function handleAnswer(answer) {

      localPeerConnection.setRemoteDescription(new RTCSessionDescription({type: 'answer',sdp: answer}))
        .catch((error) => {
          console.error('Error setting remote description:', error);
        });
    }

    // Handle ICE candidate from remote peer
    function handleCandidate(candidate) {
      const peerConnection = localPeerConnection || remotePeerConnection;
      peerConnection.addIceCandidate(new RTCIceCandidate({ type: 'candidate', candidate: candidate.candidate , sdpMid: candidate.sdpMid, sdpMLineIndex: candidate.sdpMLineIndex}))
        .catch((error) => {
          console.error('Error adding ICE candidate:', error);
        });
    }

    function sendToDataChannel(data) {
        if (localDataChannel && localDataChannel.readyState === 'open') {
    if(aesKey){
            const plainText = JSON.stringify(data);
            encryptData(plainText)
              .then((encryptedData) => {
                  localDataChannel.send(encryptedData);
              })
              .catch((error) => {
                console.error('Error decrypting data:', error);
              });
              }else{
                console.log('No aesKey');
              }
              }else{
                            console.log('Data channel is not open');
    }

    }

    // Send data to the signaling server
    function sendToSignalingServer(message) {
      socket.send(JSON.stringify(message));
    }




      // Function to import the key from base64
              async function importKey(base64Key) {
                  const rawKey = base64ToArrayBuffer(base64Key);
                  return crypto.subtle.importKey(
                      'raw',
                      rawKey,
                      { name: 'AES-GCM' },
                      false,
                      ['encrypt', 'decrypt']
                  );
              }

              // Convert a base64 string to an ArrayBuffer
              function base64ToArrayBuffer(base64) {
                  const binaryString = atob(base64);
                  const len = binaryString.length;
                  const bytes = new Uint8Array(len);
                  for (let i = 0; i < len; i++) {
                      bytes[i] = binaryString.charCodeAt(i);
                  }
                  return bytes.buffer;
              }

            // Generate a random nonce
            function generateNonce(length) {
                const array = new Uint8Array(length);
                crypto.getRandomValues(array);
                return array;
            }

            // Encrypt data
            async function encryptData(plainText) {
                if (!aesKey) throw new Error('AES key is not initialized');
                const key = await aesKey;
                const nonce = generateNonce(12); // 12 bytes nonce
                const encodedText = new TextEncoder().encode(plainText);

                try {
                    const encryptedData = await crypto.subtle.encrypt(
                        {
                            name: 'AES-GCM',
                            iv: nonce,
                            tagLength: 128 // Tag length set to 128 bits
                        },
                        key,
                        encodedText
                    );

                    const encryptedBytes = new Uint8Array(encryptedData);

                    // Concatenate nonce and ciphertext
                    const concatenatedBytes = new Uint8Array(nonce.length + encryptedBytes.length);
                    concatenatedBytes.set(nonce);
                    concatenatedBytes.set(encryptedBytes, nonce.length);

                    // Convert to base64
                    const base64String = btoa(String.fromCharCode(...concatenatedBytes));
                    return base64String;
                } catch (error) {
                    console.error('Encryption error:', error);
                    throw error;
                }
            }

            // Decrypt data
            async function decryptData(encryptedText) {
                if (!aesKey) throw new Error('AES key is not initialized');

                const encryptedBytes = Uint8Array.from(atob(encryptedText), c => c.charCodeAt(0));

                const nonceLength = 12; // 12 bytes for nonce
                const key = await aesKey;
                const nonce = encryptedBytes.slice(0, nonceLength);
                const ciphertext = encryptedBytes.slice(nonceLength);

                try {
                    const decryptedData = await crypto.subtle.decrypt(
                        {
                            name: 'AES-GCM',
                            iv: nonce,
                            tagLength: 128 // Tag length set to 128 bits
                        },
                        key,
                        ciphertext
                    );

                    return new TextDecoder().decode(decryptedData);
                } catch (error) {
                    console.error('Decryption error:', error);
                    throw error;
                }
            }