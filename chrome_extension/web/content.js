let sessionData = {};
const userFields = 'input[name="username"], input[name="user"], input[name="userId"], input[name="userid"]';
const passwordFields = 'input[name="password"], input[name="pass"], input[name="pwd"], input[name="passwd"], input[name="Passwd"]';
const confirmPasswordFields = 'input[name="confirm"], input[name="reenter"], input[name="password_confirmation"], input[name="password_confirm"], input[name="re_password"], input[name="PasswdAgain"]';
const emailFields = 'input[type="email"], input[name="email"], input[name="Email"], input[name="e-mail"], input[name="E-mail"]';


document.addEventListener('focusin', (event) => {
console.log('content.js: focusin event');
  if (event.target.name === 'password' || event.target.name === 'pass' || event.target.name === 'pwd' || event.target.name === 'passwd' || event.target.name === 'Passwd') {
  detectAndAutofillForm();
  }
});
document.addEventListener('focusout', (event) => {
console.log('content.js: focusout event');
  if (event.target.name === 'Username' || event.target.name === 'username' || event.target.name === 'Email' || event.target.name === 'email' || event.target.type === 'email' || event.target.type === 'username' || event.target.name === 'user' || event.target.name === 'userid' || event.target.name === 'userId') {

    sessionData['username'] = event.target.value;
  console.log('content.js: sessionData: ', sessionData);
  }
});

function detectAndAutofillForm() {
    const forms = document.forms;
    for (let form of forms) {
      const action = form.action.toLowerCase();
      const formFields = Array.from(form.elements).map(el => el.name.toLowerCase());
      if (isRegistrationForm(action, formFields, form.elements)) {
          const usernameField = document.querySelector(userFields);
          const emailField = document.querySelector(emailFields);
                let username;
                let email;
            if (!usernameField && !emailField) {
            if(!sessionData['username']){
              alert('Email or username not found');
              return;
            }
        }
            username = sessionData['username'] || usernameField.value;
            email = sessionData['username'] || sessionData['username'] || emailField.value;



        chrome.runtime.sendMessage({target: "background", action: 'SEND_TO_DATA_CHANNEL_REGISTER', data: window.location.hostname, username: username}, (response) => {
        console.log('content.js: sendMessage response: ', response);
        });
      } else if (isLoginForm(action, formFields)) {
        chrome.runtime.sendMessage({target: "background", action: 'SEND_TO_DATA_CHANNEL_LOGIN', data: window.location.hostname }, (response) => {
        console.log('content.js: sendMessage response: ', response);
        });
      }
    }
  }

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
//if(request.target !== 'content') return;
console.log('content.js: onMessage event with request: ', request);
if (request.action === 'AUTOFILL_LOGIN') {
    autofillLoginForm(request.data);
  } else if (request.action === 'AUTOFILL_REGISTER') {
    autofillRegisterForm(request.data);
  }
  });

let popupContainer = null;

function showPopup(entries,field) {

  // Create a container for the popup if it doesn't exist
  if (!popupContainer) {
    popupContainer = document.createElement('div');
    popupContainer.id = 'popup-container';
    popupContainer.style.position = 'absolute';
    popupContainer.style.zIndex = '10000';
    popupContainer.style.backgroundColor = 'white';
    popupContainer.style.border = '1px solid black';
    popupContainer.style.padding = '10px';
    popupContainer.style.boxShadow = '0 2px 10px rgba(0,0,0,0.5)';
  } else {
    // Clear any existing entries
    popupContainer.innerHTML = '';
  }

  // Position the container near the username field
  const rect = field.getBoundingClientRect();
  popupContainer.style.top = `${rect.top + window.scrollY + field.offsetHeight}px`;
  popupContainer.style.left = `${rect.left + window.scrollX}px`;

  // Create a list of entries
  entries.forEach(entry => {
    let entryDiv = document.createElement('div');
    entryDiv.style.marginBottom = '5px';
    entryDiv.style.cursor = 'pointer';
    entryDiv.textContent = `${entry.username}`;
    entryDiv.onclick = () => {
      fillForm(entry);
      closePopup();
    };
    popupContainer.appendChild(entryDiv);
  });

  let lastEntry = document.createElement('div');
    lastEntry.style.marginBottom = '5px';
    lastEntry.style.cursor = 'pointer';
    lastEntry.textContent = `Create or Update Entry`;
    lastEntry.onclick = () => {
   const usernameField = document.querySelector(userFields);
               const emailField = document.querySelector(emailFields);
                 let username;
                               let email;
                           if (!usernameField && !emailField) {
                           if(!sessionData['Username']){
                             alert('Email or username not found');
                             return;
                           }
                       }
                           username = sessionData['username'] || usernameField.value;
                           email = sessionData['username'] || sessionData['username'] || emailField.value;

           chrome.runtime.sendMessage({target: "background", action: 'SEND_TO_DATA_CHANNEL_REGISTER', data: window.location.hostname, username: username}, (response) => {
           console.log('content.js: sendMessage response: ', response);
           });
        closePopup();
    }
    popupContainer.appendChild(lastEntry);

 // Add the container to the body if it's not already added
   if (!popupContainer.parentElement) {
     document.body.appendChild(popupContainer);
  setTimeout(() => {
            document.addEventListener('click', handleOutsideClick);
        }, 150); // Addi
   }
}

function fillForm(entry) {
    const usernameField = document.querySelector(userFields);
    const emailField = document.querySelector( emailFields);
    const passwordField = document.querySelector( passwordFields);
    const confirmPasswordField = document.querySelector(confirmPasswordFields);
    const email = entry.username

    if (usernameField) {
      usernameField.value = entry.username;
                      usernameField.dispatchEvent(new Event('input', { bubbles: true })); // Trigger input event

    }
    if (emailField) {
      emailField.value = email;
                      emailField.dispatchEvent(new Event('input', { bubbles: true })); // Trigger input event

    }
    if (passwordField) {
        passwordField.value = entry.password;
                        passwordField.dispatchEvent(new Event('input', { bubbles: true })); // Trigger input event

    }
    if (confirmPasswordField) {
        confirmPasswordField.value = entry.password; // Ensure the confirm password field matches
                        confirmPasswordField.dispatchEvent(new Event('input', { bubbles: true })); // Trigger input event

    }

}

function isRegistrationForm(action, formFields, elements) {
  const registrationKeywords = ['register', 'signup', 'create account'];
  const registrationFieldTypes = ['username', 'email', 'password', 'confirm_password'];

  return registrationKeywords.some(keyword => action.includes(keyword)) ||
    registrationFieldTypes.every(type => Array.from(elements).some(el => el.type === type || el.name.toLowerCase().includes(type)));
}

function isLoginForm(action, formFields) {
  const loginKeywords = ['login', 'signin'];
  const loginFields = ['username', 'password'];
  return loginKeywords.some(keyword => action.includes(keyword)) ||
    loginFields.every(field => formFields.includes(field));
}

function autofillLoginForm(entries) {
  const usernameField = document.querySelector(userFields);
  const passwordField = document.querySelector( passwordFields);
  if (!usernameField && !passwordField) {
    console.error('Login fields not found');
    return;
  }
    if(!usernameField || usernameField.offsetHeight === 0 && usernameField.getBoundingClientRect().top === 0 && usernameField.getBoundingClientRect().left === 0){
    showPopup(entries,passwordField);
    }else{
   showPopup(entries,usernameField);
   }
}

function autofillRegisterForm(entries) {
  const usernameField = document.querySelector( userFields);
  const emailField = document.querySelector( emailFields);
  const passwordField = document.querySelector( passwordFields);
  const confirmPasswordField = document.querySelector(confirmPasswordFields);

  if (!usernameField && !emailField && !passwordField && !confirmPasswordField) {
    console.error('Registration fields not found');
    return;
  }

   fillForm(entries[0]);

  }

function closePopup() {
  if (popupContainer && popupContainer.parentElement) {
    document.body.removeChild(popupContainer);
    popupContainer = null;
    document.removeEventListener('click', handleOutsideClick);
  }
}

function handleOutsideClick(event) {
  if (popupContainer && !popupContainer.contains(event.target)) {
    closePopup();
  }
}

