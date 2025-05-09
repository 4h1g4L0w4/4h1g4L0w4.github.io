# 1. Imagen oficial de Jekyll con Ruby y Bundler
FROM jekyll/jekyll:latest

# 2. Directorio de trabajo dentro del contenedor
WORKDIR /srv/jekyll

# 3. Copia todos los archivos de tu sitio al contenedor
COPY . .

# 4. (Opcional) Ajusta la versión de Bundler si tu Gemfile lo necesita
#RUN gem install bundler

# 5. Instala las dependencias declaradas en Gemfile
RUN bundle install

# 6. Ejecuta el build de Jekyll, que genera la carpeta _site/
RUN bundle exec jekyll build

# 7. Por defecto sirve el sitio (útil para debug), pero no lo usaremos en despliegue
CMD ["jekyll", "serve", "--host", "0.0.0.0"]
