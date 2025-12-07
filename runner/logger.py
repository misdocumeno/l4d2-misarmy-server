import logging

logger = logging.getLogger('runner')

console_handler = logging.StreamHandler()

formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)

logger.addHandler(console_handler)
