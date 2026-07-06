# more_pic

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## 배포방법
모어픽 web 호스팅 방법
(*node js 버전을 최신으로 해두는것이 좋음*)

firebase login  (gnet google 계정으로 로그인, (개인 계정으로 로그인 되어있을 시, firebase logout 후 다시 로그인 할 것))

firebase init

Hosting 2개 중 제일 긴거 스페이스바로 선택 이후 엔터

What do you want to use as your public directory? 여기에 build web 이라고 쳐야 됨

계속 y 누르면 다가 github에도 올릴거냐는 거에만 n


flutter build web (index.html 감지하여 빌드 중)\

마지막으로

firebase deploy --only hosting  하면 

작업된 프로젝트가 올라간다 


