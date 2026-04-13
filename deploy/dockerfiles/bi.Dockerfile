FROM nginx:1.27-alpine
COPY flirtello-bi/build /usr/share/nginx/html
COPY nginx/bi-static.conf /etc/nginx/conf.d/default.conf
EXPOSE 8082
CMD ["nginx", "-g", "daemon off;"]

