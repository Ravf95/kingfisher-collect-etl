import argparse
import logging
import signal

from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings
from twisted.internet import reactor

import util
from transform.transform import database_creation

parser = argparse.ArgumentParser()
parser.add_argument("--colombia", help="run the ETL for colombia",
                    action="store_true")
parser.add_argument("--paraguay", help="run the ETL for paraguay",
                    action="store_true")

runner = CrawlerProcess(get_project_settings())


def signal_handler(sig, frame):
    runner.stop()
    logging.warning('SIGINT: scheduler finalizado')
    exit(0)


signal.signal(signal.SIGINT, signal_handler)
database = util.get_database(runner.settings)


def crawl_job():
    last_date = util.get_last_date(spidercls, database)
    logging.info(f'Descargando datos desde {last_date}')
    settings = get_project_settings()
    runner = CrawlerProcess(settings)
    return runner.crawl(spidercls, from_date=last_date)


def schedule_next_crawl(null, sleep_time):
    reactor.callLater(sleep_time, crawl)


def crawl():
    d = crawl_job()
    d.addCallback(schedule_next_crawl, scheduler_hours*60*60)
    d.addErrback(catch_error)


def catch_error(failure):
    logging.error(failure.value)


if __name__ == '__main__':
    arguments = parser.parse_args()
    if arguments.colombia:
        param_name = 'EMPATIA_ETL_SCHEDULER_HOURS_COLOMBIA'
        spider_name = 'colombia'
    else:
        param_name = 'EMPATIA_ETL_SCHEDULER_HOURS_PARAGUAY'
        spider_name = 'paraguay_dncp_records'

    spidercls = runner.spider_loader.load(spider_name)
    database_creation(database, spidercls.schema)
    scheduler_hours = runner.settings.get(param_name, 1)
    logging.info(f'Configurando scheduler {spider_name} a correr cada {scheduler_hours} horas')
    crawl()
    reactor.run()
