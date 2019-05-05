from distutils.core import setup
setup(name='zocspendfrom',
      version='1.0',
      description='Command-line utility for zoc "coin control"',
      author='CarlosM',
      author_email='cmelx@tutanota.com',
      requires=['python-bitcoinrpc'],
      scripts=['spendfrom.py'],
      )
