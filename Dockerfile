FROM python:3.11 # <imageName>

RUN apt-get update \
    && pip install --no-cache-dir -r requirements.txt
# cmd & installation needed during build
WORKDIR

EXPOSE 5000
COPY ./<dir> 
# copy code

CMD ["python", "app.py"]
ENV # set env var


# ENTRYPOINT: set main cmd running inside container
FROM ubuntu:latest
COPY script1.sh /script1.sh 
# script1.sh: local src file; /script1.sh:dest path in docker img
ENTRYPOINT ["/myscript.sh"]
CMD ["param1", "param2"]