FROM python:3.6
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
RUN mkdir /code/resports
WORKDIR /code
ADD requirements.txt export_xml_data_elastic.py /code/
RUN pip install -r requirements.txt
ENTRYPOINT ["python", "/code/export_xml_data_elastic.py"]