#  About the project

Starter is a super-basic multi-user chat application that uses [Laravel 11](https://github.com/alex3493/starter-11) project as backend.

Features:

- User can create an account and get instant access to chat list.
- User can log in from multiple devices, a dedicated access token will be created for each device.
- Auth data is stored in secure chain, no need to re-login until user explicitly logs out.
- User can update profile and logout and / or delete account.
- User can create new chats.
- User can join existing chats.
- User can leave a previously joined chat.
- User can list messages of a joined chat.
- User can add messages to a joined chat.
- User can edit chat title if he is the first chat user (chat creator, by default).
- User can delete own messages.

# Web sockets

All chat activity is automatically shown on all connected devices. We are using [Laravel Reverb](https://reverb.laravel.com/) as WS engine, however there is an option to use [Pusher](https://pusher.com).
WS service switch requires settings update on both API side and mobile application.
There is a significant limitation: live updates work across different accounts only, i.e. if you are logged in as same user on multiple devices, updated may not be reflected on another device.

# How to install

Current default settings allow running the app locally on single machine. Being a basic demo (proof of concept) project it is not targeted for production environments.

- Make sure you have installed and launched backend API.
- Clone this project in XCode and run the application in simulator(s).

