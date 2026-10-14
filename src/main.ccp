#include <Geode/Geode.hpp>
#include <Geode/modify/MenuLayer.hpp>
#include <Geode/modify/PauseLayer.hpp>
#include <Geode/modify/PlayLayer.hpp>

using namespace geode::prelude;

// ---------------------------------------------------------------------------
// Tráº¡ng thĂ¡i noclip (lÆ°u láº¡i giá»¯a cĂ¡c láº§n má»Ÿ game)
// ---------------------------------------------------------------------------
namespace noclip {
	constexpr auto KEY = "noclip-enabled";

	inline bool isEnabled() {
		return Mod::get()->getSavedValue<bool>(KEY, false);
	}

	inline void setEnabled(bool value) {
		Mod::get()->setSavedValue<bool>(KEY, value);
	}

	inline void notify(bool value) {
		Notification::create(
			value ? "Noclip: ON" : "Noclip: OFF",
			value ? NotificationIcon::Success : NotificationIcon::Info,
			0.8f
		)->show();
	}
}

// ---------------------------------------------------------------------------
// Popup giao diá»‡n chĂ­nh
// ---------------------------------------------------------------------------
class NoclipPopup : public geode::Popup<> {
protected:
	CCMenuItemToggler* m_toggler = nullptr;
	CCLabelBMFont* m_statusLabel = nullptr;

	bool setup() override {
		this->setTitle("Noclip");

		// Khung ná»n tá»‘i bo gĂ³c chá»©a ná»™i dung
		auto panel = CCScale9Sprite::create("square02b_001.png", {0, 0, 80, 80});
		panel->setColor({0, 0, 0});
		panel->setOpacity(110);
		panel->setContentSize({m_size.width - 40.f, 92.f});
		m_mainLayer->addChildAtPosition(panel, Anchor::Center, {0, -2});

		// NhĂ£n bĂªn trĂ¡i
		auto label = CCLabelBMFont::create("Enable Noclip", "bigFont.fnt");
		label->setScale(0.55f);
		label->setAnchorPoint({0.f, 0.5f});
		m_mainLayer->addChildAtPosition(label, Anchor::Center, {-m_size.width / 2 + 38.f, 18});

		// NĂºt gáº¡t bĂªn pháº£i
		m_toggler = CCMenuItemToggler::createWithStandardSprites(
			this, menu_selector(NoclipPopup::onToggle), 0.9f
		);
		m_toggler->toggle(noclip::isEnabled());
		m_buttonMenu->addChildAtPosition(m_toggler, Anchor::Center, {m_size.width / 2 - 52.f, 18});

		// Tráº¡ng thĂ¡i ON / OFF
		m_statusLabel = CCLabelBMFont::create("", "goldFont.fnt");
		m_statusLabel->setScale(0.75f);
		m_mainLayer->addChildAtPosition(m_statusLabel, Anchor::Center, {0, -14});

		// MĂ´ táº£
		auto desc = CCLabelBMFont::create(
			"You will not die when touching\nobstacles while enabled.",
			"chatFont.fnt"
		);
		desc->setScale(0.62f);
		desc->setOpacity(190);
		desc->setAlignment(kCCTextAlignmentCenter);
		m_mainLayer->addChildAtPosition(desc, Anchor::Center, {0, -42});

		this->updateStatus(noclip::isEnabled());
		return true;
	}

	void updateStatus(bool enabled) {
		m_statusLabel->setString(enabled ? "ENABLED" : "DISABLED");
		m_statusLabel->setColor(enabled ? ccColor3B{90, 255, 120} : ccColor3B{255, 90, 90});
	}

	void onToggle(CCObject*) {
		// Callback cháº¡y TRÆ¯á»C khi nĂºt Ä‘á»•i tráº¡ng thĂ¡i, nĂªn giĂ¡ trá»‹ má»›i lĂ  phá»§ Ä‘á»‹nh cá»§a hiá»‡n táº¡i
		bool enabled = !m_toggler->isToggled();
		noclip::setEnabled(enabled);
		this->updateStatus(enabled);
		noclip::notify(enabled);
	}

public:
	static NoclipPopup* create() {
		auto ret = new NoclipPopup();
		if (ret->initAnchored(280.f, 190.f)) {
			ret->autorelease();
			return ret;
		}
		delete ret;
		return nullptr;
	}
};

// ---------------------------------------------------------------------------
// Menu chĂ­nh: thĂªm nĂºt "NC" Ä‘á»ƒ má»Ÿ popup
// ---------------------------------------------------------------------------
class $modify(NoclipMenuLayer, MenuLayer) {
	bool init() {
		if (!MenuLayer::init()) return false;

		auto menu = this->getChildByID("bottom-menu");
		if (!menu) return true;

		auto text = CCLabelBMFont::create("NC", "bigFont.fnt");
		text->setScale(0.7f);
		auto sprite = CircleButtonSprite::create(text, CircleBaseColor::Green, CircleBaseSize::Medium);

		auto btn = CCMenuItemSpriteExtra::create(sprite, this, menu_selector(NoclipMenuLayer::onOpenNoclip));
		btn->setID("noclip-button"_spr);
		menu->addChild(btn);
		menu->updateLayout();
		return true;
	}

	void onOpenNoclip(CCObject*) {
		if (auto popup = NoclipPopup::create()) popup->show();
	}
};

// ---------------------------------------------------------------------------
// Menu táº¡m dá»«ng: nĂºt báº­t/táº¯t nhanh ngay trong mĂ n chÆ¡i
// ---------------------------------------------------------------------------
class $modify(NoclipPauseLayer, PauseLayer) {
	void customSetup() {
		PauseLayer::customSetup();

		auto winSize = CCDirector::get()->getWinSize();

		auto offSpr = ButtonSprite::create("Noclip: OFF", 110, true, "bigFont.fnt", "GJ_button_04.png", 30.f, 0.6f);
		auto onSpr = ButtonSprite::create("Noclip: ON", 110, true, "bigFont.fnt", "GJ_button_01.png", 30.f, 0.6f);

		auto toggler = CCMenuItemToggler::create(offSpr, onSpr, this, menu_selector(NoclipPauseLayer::onNoclipToggle));
		toggler->toggle(noclip::isEnabled());
		toggler->setID("noclip-toggler"_spr);

		auto menu = CCMenu::create();
		menu->setPosition({0, 0});
		toggler->setPosition({winSize.width - 85.f, 35.f});
		menu->addChild(toggler);
		this->addChild(menu);
	}

	void onNoclipToggle(CCObject* sender) {
		// Callback cháº¡y trÆ°á»›c khi nĂºt Ä‘á»•i tráº¡ng thĂ¡i
		auto toggler = static_cast<CCMenuItemToggler*>(sender);
		bool enabled = !toggler->isToggled();
		noclip::setEnabled(enabled);
		noclip::notify(enabled);
	}
};

// ---------------------------------------------------------------------------
// Logic noclip + huy hiá»‡u "NOCLIP" nhá» trong mĂ n chÆ¡i
// ---------------------------------------------------------------------------
class $modify(NoclipPlayLayer, PlayLayer) {
	struct Fields {
		CCLabelBMFont* m_badge = nullptr;
	};

	void setupHasCompleted() {
		PlayLayer::setupHasCompleted();

		auto winSize = CCDirector::get()->getWinSize();
		auto badge = CCLabelBMFont::create("NOCLIP", "bigFont.fnt");
		badge->setScale(0.35f);
		badge->setOpacity(130);
		badge->setColor({255, 90, 90});
		badge->setAnchorPoint({0.f, 1.f});
		badge->setPosition({8.f, winSize.height - 6.f});
		badge->setZOrder(100);
		badge->setVisible(noclip::isEnabled());
		this->addChild(badge);
		m_fields->m_badge = badge;
	}

	void postUpdate(float dt) {
		PlayLayer::postUpdate(dt);
		if (m_fields->m_badge) {
			m_fields->m_badge->setVisible(noclip::isEnabled());
		}
	}

	void destroyPlayer(PlayerObject* player, GameObject* object) {
		// Bá» qua má»i va cháº¡m, trá»« "anticheat spike" ná»™i bá»™ cá»§a game
		if (noclip::isEnabled() && object != m_anticheatSpike) return;
		PlayLayer::destroyPlayer(player, object);
	}
};
