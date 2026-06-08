import sys
import unittest

TEST_MODULES = [
    "air_tests",
    "geocode_tests",
]


def load_suite():
    suite = unittest.TestSuite()

    for test_module in TEST_MODULES:
        try:
            mod = __import__(test_module, globals(), locals(), ["suite"])
            suitefn = getattr(mod, "suite")
            suite.addTest(suitefn())
        except (ImportError, AttributeError):
            suite.addTest(unittest.defaultTestLoader.loadTestsFromName(test_module))

    return suite


if __name__ == "__main__":
    result = unittest.TextTestRunner(verbosity=2).run(load_suite())
    sys.exit(0 if result.wasSuccessful() else 1)
