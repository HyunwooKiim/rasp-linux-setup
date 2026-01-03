# Raspberry Pi Linux Bootstrap

라즈베리파이(Ubuntu Server)를 **서버 운영용으로 초기 세팅**하기 위한 부트스트랩 스크립트입니다.

**이 스크립트를 실행하기 전, 기본적인 DHCP 네트워크 설정은 반드시 되어 있어야 합니다.**
(Wi-Fi 또는 유선 LAN 중 하나라도 DHCP로 IP를 정상 할당받을 수 있어야 합니다)

이 스크립트는 다음을 한 번에 수행합니다.

- DHCP 연결 확인 후 고정 IP 설정
- Docker / Docker Compose 설치
- Java 25 (Temurin) 설치
- SSH ed25519 키 생성 및 설정
- GitHub Actions용 `secrets.txt` 자동 생성
- 실행 후 스크립트 및 clone 디렉토리 자동 정리

---

## 요구 환경

- Raspberry Pi (Wi-Fi 사용 기준)
- Ubuntu Server (Jammy 기준)
- 인터넷 연결 가능 (DHCP)
- sudo 권한

---

## 사용 방법

### 1. 레포지토리 클론

```bash
git clone <https://github.com/HyunwooKiim/rasp-linux-setup.git>
cd rasp-linux-setup
```

### 2. 실행 권한 부여

```bash
chmod +x setup.sh
```

### 3. 스크립트 실행

```bash
sudo ./setup.sh
```

---

## 실행 중 주의 사항

### 고정 IP 적용 단계

스크립트 중간에 다음 단계가 나타납니다.

- 현재 DHCP로 할당된 IP를 기준으로 고정 IP 설정
- `netplan try` 실행
- **네트워크 연결이 유지되는 것이 확인되면 ENTER 입력**

ENTER를 누르지 않으면 자동으로 롤백됩니다.

---

## 실행 후 결과

### 생성되는 파일

- `~/secrets.txt`
- `~/.ssh/id_ed25519`
- `~/.ssh/id_ed25519.pub`
- `~/.ssh/authorized_keys`

### 자동 정리

- 실행한 `setup.sh` 파일 삭제
- `rasp-linux-setup/` 디렉토리 자동 삭제 (git clone으로 실행한 경우)

---

## secrets.txt 설명

`secrets.txt`는 **GitHub Actions Secrets를 설정하기 위한 안내 파일**입니다.

### 주요 항목

```bash
PI_HOST=<서버 IP>
PI_USER=<서버 사용자>

cat ~/.ssh/id_ed25519
```

- `cat ~/.ssh/id_ed25519` 명령을 실행해 나오는 **private key 전체를**
- GitHub → Repository → Settings → Secrets → Actions
- `PI_SSH_KEY` 이름으로 등록합니다.

`secrets.txt` 자체는 GitHub에 커밋하지 마세요.

---

## GitHub Actions에 등록해야 할 Secrets

필수 Secrets 목록:

- `PI_HOST`
- `PI_USER`
- `PI_SSH_KEY`
- `GHCR_TOKEN`

애플리케이션용 Secrets:

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `SPRING_PROFILES_ACTIVE`
- `TZ`

---

## 보안 주의사항

- SSH private key는 **절대 GitHub 저장소에 커밋하지 마세요**
- `secrets.txt`는 로컬 참고용 파일입니다
- 운영 환경에서는 SSH 비밀번호 로그인을 비활성화하는 것을 권장합니다

---

## 권장 다음 단계

- SSH 비밀번호 로그인 비활성화
- GitHub Actions CI/CD 연결
- Docker Compose 기반 서비스 배포
- 도메인 및 HTTPS 설정

---

## 요약

이 스크립트는:

- 한 번 실행하고 버리는 초기화 도구이며
- 서버 환경을 빠르게 재현 가능하게 만들고
- CI/CD 연결을 위한 최소한의 준비를 자동화합니다.
