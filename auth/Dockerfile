FROM dart:stable-sdk

WORKDIR /app
ADD . .

RUN dart pub get 
RUN dart pub global activate conduit
EXPOSE 6100

ENTRYPOINT ["dart", "run", "conduit:conduit", "serve", "--port", "6100"]