use crate::artifact::*;

#[derive(Debug, PartialEq)]
pub enum ParseError {
    UnexpectedEof,
    Expected(char, usize),
    UnknownField(String),
    UnknownTargetKind(String),
    UnknownInputKind(String),
    UnknownEvidenceKind(String),
    MissingTarget(Ident),
    MissingNonclaim(Ident),
    EmptyNonclaim,
    InvalidNumber(String),
    InvalidString(String),
}

pub struct Parser<'a> {
    src: &'a [u8],
    pos: usize,
}

impl<'a> Parser<'a> {
    pub fn new(src: &'a str) -> Self {
        Self {
            src: src.as_bytes(),
            pos: 0,
        }
    }

    pub fn parse(mut self) -> Result<Harness, ParseError> {
        self.ws();
        self.expect_word("harness")?;
        self.ws();
        let id = self.parse_ident()?;
        self.ws();
        self.expect(b'{')?;
        self.ws();

        let mut target = None;
        let mut inputs = Vec::new();
        let mut assertions = Vec::new();
        let mut evidence = None;
        let mut nonclaim = None;
        let mut cites = Vec::new();

        while self.peek() != Some(b'}') {
            match self.peek_word() {
                Some("target") => target = Some(self.parse_target()?),
                Some("input") => inputs.push(self.parse_input()?),
                Some("assert") => assertions.push(self.parse_assert()?),
                Some("evidence") => evidence = Some(self.parse_evidence()?),
                Some("nonclaim") => nonclaim = Some(self.parse_nonclaim()?),
                Some("cite") => cites.push(self.parse_cite()?),
                Some(other) => return Err(ParseError::UnknownField(other.into())),
                None => return Err(ParseError::UnexpectedEof),
            }
            self.ws();
        }
        self.expect(b'}')?;
        let target = target.ok_or(ParseError::MissingTarget(id.clone()))?;
        let nonclaim = nonclaim.ok_or(ParseError::MissingNonclaim(id.clone()))?;
        Ok(Harness {
            id,
            target,
            inputs,
            assertions,
            evidence,
            nonclaim,
            cites,
        })
    }

    fn parse_target(&mut self) -> Result<Target, ParseError> {
        self.consume_word("target")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let kind = match self.parse_ident()?.0.as_str() {
            "shell" => TargetKind::Shell,
            "binary" => TargetKind::Binary,
            "function" => TargetKind::Function,
            "wasm" => TargetKind::Wasm,
            other => return Err(ParseError::UnknownTargetKind(other.into())),
        };
        self.ws();
        let body = self.parse_string()?;
        self.ws();
        self.expect(b';')?;
        Ok(Target { kind, body })
    }

    fn parse_input(&mut self) -> Result<Input, ParseError> {
        self.consume_word("input")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let kind = match self.parse_ident()?.0.as_str() {
            "file" => InputKind::File,
            "stdin" => InputKind::Stdin,
            "env" => InputKind::Env,
            other => return Err(ParseError::UnknownInputKind(other.into())),
        };
        self.ws();
        let body = self.parse_string()?;
        self.ws();
        self.expect(b';')?;
        Ok(Input { kind, body })
    }

    fn parse_assert(&mut self) -> Result<Assertion, ParseError> {
        self.consume_word("assert")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let a = if self.peek_word() == Some("exit") {
            self.consume_word("exit")?;
            self.ws();
            self.expect(b'=')?;
            self.expect(b'=')?;
            self.ws();
            Assertion::Exit(self.parse_number()? as i32)
        } else if self.peek_word() == Some("stdout") {
            self.consume_word("stdout")?;
            self.ws();
            if self.peek_word() == Some("contains") {
                self.consume_word("contains")?;
                self.ws();
                Assertion::StdoutContains(self.parse_string()?)
            } else if self.peek_word() == Some("matches") {
                self.consume_word("matches")?;
                self.ws();
                Assertion::StdoutMatches(self.parse_string()?)
            } else {
                return Err(ParseError::UnknownField("stdout ?".into()));
            }
        } else if self.peek_word() == Some("file") {
            self.consume_word("file")?;
            self.ws();
            self.consume_word("exists")?;
            self.ws();
            Assertion::FileExists(self.parse_string()?)
        } else {
            return Err(ParseError::UnknownField("assert ?".into()));
        };
        self.ws();
        self.expect(b';')?;
        Ok(a)
    }

    fn parse_evidence(&mut self) -> Result<Evidence, ParseError> {
        self.consume_word("evidence")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let kind = match self.parse_ident()?.0.as_str() {
            "receipt" => EvidenceKind::Receipt,
            "log" => EvidenceKind::Log,
            "hash" => EvidenceKind::Hash,
            other => return Err(ParseError::UnknownEvidenceKind(other.into())),
        };
        self.ws();
        let body = self.parse_string()?;
        self.ws();
        self.expect(b';')?;
        Ok(Evidence { kind, body })
    }

    fn parse_nonclaim(&mut self) -> Result<NonEmpty, ParseError> {
        self.consume_word("nonclaim")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let s = self.parse_string()?;
        self.ws();
        self.expect(b';')?;
        NonEmpty::new(s).ok_or(ParseError::EmptyNonclaim)
    }

    fn parse_cite(&mut self) -> Result<Cite, ParseError> {
        self.consume_word("cite")?;
        self.ws();
        self.expect(b':')?;
        self.ws();
        let instrument = self.parse_string()?;
        self.ws();
        self.expect(b':')?;
        self.expect(b':')?;
        self.ws();
        let clause = self.parse_string()?;
        self.ws();
        self.expect(b';')?;
        Ok(Cite { instrument, clause })
    }

    fn parse_ident(&mut self) -> Result<Ident, ParseError> {
        let start = self.pos;
        while let Some(c) = self.peek() {
            if c.is_ascii_alphanumeric() || c == b'_' || c == b'-' {
                self.pos += 1;
            } else {
                break;
            }
        }
        if self.pos == start {
            return Err(ParseError::Expected('a', self.pos));
        }
        Ok(Ident(
            String::from_utf8_lossy(&self.src[start..self.pos]).into(),
        ))
    }

    fn parse_string(&mut self) -> Result<String, ParseError> {
        self.expect(b'"')?;
        let mut bytes: Vec<u8> = Vec::new();
        while let Some(c) = self.peek() {
            if c == b'"' {
                self.pos += 1;
                return String::from_utf8(bytes)
                    .map_err(|_| ParseError::InvalidString("invalid utf8".into()));
            }
            if c == b'\\' {
                self.pos += 1;
                match self.peek() {
                    Some(b'"') => {
                        bytes.push(b'"');
                        self.pos += 1;
                    }
                    Some(b'\\') => {
                        bytes.push(b'\\');
                        self.pos += 1;
                    }
                    Some(o) => {
                        bytes.push(o);
                        self.pos += 1;
                    }
                    None => return Err(ParseError::UnexpectedEof),
                }
                continue;
            }
            bytes.push(c);
            self.pos += 1;
        }
        Err(ParseError::InvalidString("unterminated".into()))
    }
    fn parse_number(&mut self) -> Result<i64, ParseError> {
        let start = self.pos;
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        while let Some(c) = self.peek() {
            if c.is_ascii_digit() {
                self.pos += 1;
            } else {
                break;
            }
        }
        if self.pos == start {
            return Err(ParseError::InvalidNumber("empty".into()));
        }
        std::str::from_utf8(&self.src[start..self.pos])
            .map_err(|_| ParseError::InvalidNumber("utf8".into()))?
            .parse()
            .map_err(|_| ParseError::InvalidNumber("parse".into()))
    }

    fn ws(&mut self) {
        while let Some(c) = self.peek() {
            if c == b' ' || c == b'\t' || c == b'\n' || c == b'\r' {
                self.pos += 1;
            } else {
                break;
            }
        }
    }

    fn peek(&self) -> Option<u8> {
        self.src.get(self.pos).copied()
    }

    fn peek_word(&self) -> Option<&str> {
        let start = self.pos;
        let mut end = start;
        while end < self.src.len() {
            let c = self.src[end];
            if c.is_ascii_alphanumeric() || c == b'_' || c == b'-' {
                end += 1;
            } else {
                break;
            }
        }
        if end == start {
            None
        } else {
            std::str::from_utf8(&self.src[start..end]).ok()
        }
    }

    fn expect(&mut self, b: u8) -> Result<(), ParseError> {
        if self.peek() == Some(b) {
            self.pos += 1;
            Ok(())
        } else {
            Err(ParseError::Expected(b as char, self.pos))
        }
    }

    fn expect_word(&mut self, w: &str) -> Result<(), ParseError> {
        if self.peek_word() == Some(w) {
            self.pos += w.len();
            Ok(())
        } else {
            Err(ParseError::Expected(
                w.chars().next().unwrap_or('?'),
                self.pos,
            ))
        }
    }

    fn consume_word(&mut self, w: &str) -> Result<(), ParseError> {
        self.expect_word(w)
    }
}
