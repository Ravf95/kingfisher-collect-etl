import hashlib
import json
import os

import scrapy


class KingfisherSpiderMixin:
    """
    Download a sample:

    .. code:: bash

        scrapy crawl spider_name -a sample=true

    Add a note to the collection:

    .. code:: bash

        scrapy crawl spider_name -a note='Started by NAME.'

    Use a proxy:

    .. code:: bash

       scrapy crawl spider_name -a http_proxy=URL -a https_proxy=URL
    """
    def __init__(self, sample=None, note=None, http_proxy=None, https_proxy=None, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # https://docs.scrapy.org/en/latest/topics/spiders.html#spider-arguments
        self.sample = sample == 'true'
        self.note = note
        self.http_proxy = http_proxy
        self.https_proxy = https_proxy

    def get_local_file_path_including_filestore(self, filename):
        """
        Prepends Scrapy's storage directory and the crawl's relative directory to the filename.
        """
        return os.path.join(self.crawler.settings['FILES_STORE'], self._get_crawl_path(), filename)

    def get_local_file_path_excluding_filestore(self, filename):
        """
        Prepends the crawl's relative directory to the filename.
        """
        return os.path.join(self._get_crawl_path(), filename)

    def save_response_to_disk(self, response, filename, data_type=None, encoding='utf-8'):
        """
        Writes the response's body to the filename in the crawl's directory.

        Writes a ``<filename>.fileinfo`` metadata file in the crawl's directory, and returns a dict with the metadata.
        """
        return self._save_response_to_disk(response.body, filename, response.request.url, data_type, encoding)

    def save_data_to_disk(self, data, filename, url=None, data_type=None, encoding='utf-8'):
        """
        Writes the data to the filename in the crawl's directory.

        Writes a ``<filename>.fileinfo`` metadata file in the crawl's directory, and returns a dict with the metadata.
        """
        return self._save_response_to_disk(data, filename, url, data_type, encoding)

    def get_start_time(self, format):
        """
        Returns the formatted start time of the crawl.
        """
        return self.crawler.stats.get_value('start_time').strftime(format)

    def _save_response_to_disk(self, data, filename, url, data_type, encoding):
        self._write_file(filename, data)

        metadata = {
            'url': url,
            'data_type': data_type,
            'encoding': encoding,
        }

        self._write_file(filename + '.fileinfo', metadata)

        metadata['success'] = True
        metadata['file_name'] = filename

        return metadata

    def _write_file(self, filename, data):
        path = self.get_local_file_path_including_filestore(filename)
        os.makedirs(os.path.dirname(path), exist_ok=True)

        if isinstance(data, bytes):
            mode = 'wb'
        else:
            mode = 'w'

        with open(path, mode) as f:
            if isinstance(data, (bytes, str)):
                f.write(data)
            else:
                json.dump(data, f)

    def _get_crawl_path(self):
        name = self.name
        if self.sample:
            name += '_sample'
        return os.path.join(name, self.get_start_time('%Y%m%d_%H%M%S'))


# `scrapy.Spider` is not set up for cooperative multiple inheritance (it doesn't call `super()`), so the mixin must be
# the first declared parent class, in order for its `__init__()` and `from_crawler()` methods to be run.
#
# https://github.com/scrapy/scrapy/blob/1.8.0/scrapy/spiders/__init__.py#L25-L32
# https://docs.python.org/3.8/library/functions.html#super
# https://rhettinger.wordpress.com/2011/05/26/super-considered-super/
class BaseSpider(KingfisherSpiderMixin, scrapy.Spider):
    pass


class BaseXMLFeedSpider(KingfisherSpiderMixin, scrapy.spiders.XMLFeedSpider):
    pass


class LinksSpider(BaseSpider):
    @staticmethod
    def next_link(response):
        """
        Handling API response with a links field

        Access to ``links/next`` for the new url, and returns a Request
        """
        json_data = json.loads(response.text)
        if 'links' in json_data and 'next' in json_data['links']:
            url = json_data['links']['next']
            return scrapy.Request(
                url=url,
                meta={'kf_filename': hashlib.md5(url.encode('utf-8')).hexdigest() + '.json'}
            )

    def parse_next_link(self, response, data_type):
        if response.status == 200:

            yield self.save_response_to_disk(response, response.request.meta['kf_filename'], data_type=data_type)

            if not self.sample:
                yield self.next_link(response)
        else:
            yield {
                'success': False,
                'file_name': response.request.meta['kf_filename'],
                'url': response.request.url,
                'errors': {'http_code': response.status}
            }
