// Assert the workspace member list matches a checked-in snapshot.
// A crate added or removed without updating the snapshot fails this test.

fn members_from_cargo_toml(path: &str) -> Vec<String> {
    let s = std::fs::read_to_string(path).expect("Cargo.toml");
    // Find the members = [ ... ] block, possibly spanning lines.
    let start = s.find("members").expect("members key");
    let after = &s[start..];
    let open = after.find('[').expect("[");
    let close = after.find(']').expect("]");
    let body = &after[open + 1..close];
    let mut out: Vec<String> = body
        .split(',')
        .map(|t| t.trim().trim_matches('"').trim().to_string())
        .filter(|t| !t.is_empty())
        .collect();
    out.sort();
    out
}

#[test]
fn workspace_members_match_snapshot() {
    let members = members_from_cargo_toml("../../Cargo.toml");
    let snap = std::fs::read_to_string("../../workspace-members.txt")
        .expect("workspace-members.txt missing");
    let want: Vec<String> = snap
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    assert!(!members.is_empty(), "no members parsed from Cargo.toml");
    assert_eq!(members, want,
        "\nworkspace members drifted from snapshot.\nupdate workspace-members.txt if the change is intentional.");
}
