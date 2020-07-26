from kingfisher_scrapy.base_spider import PeriodicalSpider
from kingfisher_scrapy.util import components


class MoldovaOld(PeriodicalSpider):
    """
    Bulk download documentation
      http://opencontracting.date.gov.md/downloads
    Spider arguments
      sample
        Downloads a single JSON file containing data for 2017.
    """
    name = 'moldova_old'
    data_type = 'release_package'
    start = 2012
    stop = 2018
    pattern = 'http://opencontracting.date.gov.md/ocds-api/year/{}'
    date_format = 'year'

    def get_formatter(self):
        return components(-1)
