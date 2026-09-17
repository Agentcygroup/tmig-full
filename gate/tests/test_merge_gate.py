import importlib.util
import pathlib
import unittest

MOD_PATH = pathlib.Path(__file__).resolve().parents[1] / "merge_gate.py"
spec = importlib.util.spec_from_file_location("merge_gate", MOD_PATH)
mg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mg)
CONFIG = mg.load_json(pathlib.Path(__file__).resolve().parents[1] / "config.json")


class MergeGateTests(unittest.TestCase):
    def good(self, rank="critical", grade="A"):
        delta = {"schema":"tmig.merge.delta.v1","required_languages":["rust","go"],
                 "deltas":[{"rank":rank}]}
        harness = {"schema":"tmig.merge.harness.v1","status":"PASS","checks":[
            {"check":"r","language":"rust","required":True,"status":"PASS"},
            {"check":"g","language":"go","required":True,"status":"PASS"}]}
        ledger = {"schema":"tmig.merge.ledger-grade.v1","grade":grade,
                  "required_failed":0,"required_skipped":0}
        return delta,harness,ledger

    def test_allows_only_when_all_three_inputs_pass(self):
        d,h,l=self.good()
        self.assertEqual(mg.fail_reasons(d,h,l,CONFIG),[])

    def test_denies_failed_harness(self):
        d,h,l=self.good(); h["status"]="FAIL"
        self.assertTrue(mg.fail_reasons(d,h,l,CONFIG))

    def test_denies_missing_language_coverage(self):
        d,h,l=self.good(); h["checks"]=h["checks"][:1]
        self.assertTrue(any("uncovered" in x for x in mg.fail_reasons(d,h,l,CONFIG)))

    def test_critical_requires_A(self):
        d,h,l=self.good(grade="B")
        self.assertTrue(any("below A" in x for x in mg.fail_reasons(d,h,l,CONFIG)))

    def test_medium_accepts_B(self):
        d,h,l=self.good(rank="medium",grade="B")
        self.assertEqual(mg.fail_reasons(d,h,l,CONFIG),[])

    def test_required_skip_denies_even_if_grade_present(self):
        d,h,l=self.good(); l["required_skipped"]=1
        self.assertTrue(any("SKIP" in x for x in mg.fail_reasons(d,h,l,CONFIG)))

    def test_gate_path_is_critical(self):
        score,reasons=mg.score_delta("gate/merge_gate.py","M",5,2,CONFIG)
        self.assertGreaterEqual(score,90)
        self.assertEqual(mg.rank_for_score(score,CONFIG),"critical")

    def test_identity_of_language_mapping(self):
        self.assertEqual(mg.classify_language("go/foo.go",CONFIG),"go")
        self.assertEqual(mg.classify_language("crates/x/src/lib.rs",CONFIG),"rust")
        self.assertEqual(mg.classify_language("bindings/ruby/tmig.rb",CONFIG),"ruby")


if __name__ == "__main__":
    unittest.main()
