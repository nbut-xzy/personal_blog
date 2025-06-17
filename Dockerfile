FROM hugomods/hugo:debian-std-exts-non-root-0.147.8 AS build
WORKDIR /src
COPY --chown=hugo:hugo . .
WORKDIR /src/src
RUN hugo --minify --gc --cleanDestinationDir

FROM nginx:stable-alpine3.19 AS production

COPY --from=build /src/src/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
